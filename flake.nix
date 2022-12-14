{
  description = "cmacrae's systems configuration";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    darwin.url = github:lnl7/nix-darwin;
    home.url = github:nix-community/home-manager;
    nur.url = github:nix-community/NUR;
    rnix-lsp.url = github:nix-community/rnix-lsp;
    deploy-rs.url = github:serokell/deploy-rs;
    sops.url = github:Mic92/sops-nix;
    emacs.url = github:nix-community/emacs-overlay;

    # https://github.com/NixOS/nixpkgs/pull/203504
    ivar-nixpkgs-yabai-5_0_1.url = "github:IvarWithoutBones/nixpkgs?rev=161530fa3434ea801419a8ca33dcd97ffb8e6fee";

    # Follows
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home.inputs.nixpkgs.follows = "nixpkgs";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs";
    sops.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home, deploy-rs, sops, ivar-nixpkgs-yabai-5_0_1, ... }@inputs:
    let
      domain = "cmacr.ae";

      commonDarwinConfig = [
        ./modules/macintosh.nix
        home.darwinModules.home-manager

        {
          nix.nixPath = with inputs; [{ inherit darwin; }];
          nixpkgs.overlays = with inputs;
            [
              nur.overlay
              emacs.overlays.emacs
              emacs.overlays.package
              (self: super: {
                yabai-5_0_1 = (import ivar-nixpkgs-yabai-5_0_1 { system = "aarch64-darwin"; }).yabai;
              })
            ];
        }
      ];

    in
    {
      darwinConfigurations.macbook = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = commonDarwinConfig ++ [
          (
            { pkgs, config, ... }: {
              networking.hostName = "macbook";

              nix.distributedBuilds = true;
              nix.buildMachines =
                pkgs.lib.forEach (pkgs.lib.range 1 3) (
                  n:
                  {
                    hostName = "compute${builtins.toString n}";
                    sshUser = "root";
                    sshKey = "${config.users.users.cmacrae.home}/.ssh/id_rsa";
                    systems = [ "aarch64-linux" "x86_64-linux" ];
                    maxJobs = 16;
                  }
                );

              home-manager.users.cmacrae = {
                home.packages = [
                  deploy-rs.defaultPackage.x86_64-darwin
                ];
              };

              homebrew.masApps = {
                Xcode = 497799835;
              };

              homebrew.brews = [ "ios-deploy" ];
            }
          )
        ];
      };

      darwinConfigurations.workbook = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = commonDarwinConfig ++ [
          (
            { pkgs, ... }: {
              networking.hostName = "workbook";

              home-manager.users.cmacrae = {
                home.packages = with pkgs; [
                  awscli
                  aws-iam-authenticator
                  aws-vault
                  terraform-docs
                  vault
                ];
              };

              homebrew.taps = [ "FelixKratz/formulae" ];
              homebrew.brews = [
                "ical-buddy"
                "sketchybar"
              ];

              homebrew.casks = [
                "docker"
                "jiggler"
                "sf-symbols"
              ];

              services.skhd.skhdConfig = builtins.readFile "${self}/conf.d/skhd.conf";

              services.yabai = {
                enable = true;
                package = pkgs.yabai-5_0_1;
                enableScriptingAddition = true;
                config = {
                  window_border = "on";
                  window_border_width = 3;
                  active_window_border_color = "0xff81a1c1";
                  normal_window_border_color = "0xff3b4252";
                  window_border_hidpi = "on";
                  focus_follows_mouse = "autoraise";
                  mouse_follows_focus = "off";
                  mouse_drop_action = "stack";
                  window_placement = "second_child";
                  window_opacity = "off";
                  window_topmost = "on";
                  window_shadow = "float";
                  window_origin_display = "focused";
                  active_window_opacity = "1.0";
                  normal_window_opacity = "1.0";
                  split_ratio = "0.50";
                  auto_balance = "on";
                  mouse_modifier = "alt";
                  mouse_action1 = "move";
                  mouse_action2 = "resize";
                  layout = "bsp";
                  top_padding = 10;
                  bottom_padding = 10;
                  left_padding = 10;
                  right_padding = 10;
                  window_gap = 10;
                  external_bar = "main:49:0";
                };

                extraConfig = ''
                  # rules
                  yabai -m rule --add app='System Preferences' manage=off
                  yabai -m rule --add app='Yubico Authenticator' manage=off
                  yabai -m rule --add app='YubiKey Manager' manage=off
                  yabai -m rule --add app='YubiKey Personalization Tool' manage=off

                  # signals
                  yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
                  yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces"
                  yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces"
                '';
              };

              launchd.user.agents.yabai.serviceConfig.StandardErrorPath = "/tmp/yabai.log";
              launchd.user.agents.yabai.serviceConfig.StandardOutPath = "/tmp/yabai.log";
            }
          )
        ];
      };

      nixosConfigurations.net1 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./modules/common.nix
          ./modules/net1.nix
          sops.nixosModules.sops

          {
            sops.defaultSopsFile = ./secrets.yaml;
            sops.secrets.net1_wireguard_privatekey = { };
          }
        ];
      };

      nixosConfigurations.compute1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/common.nix
          ./modules/compute.nix

          {
            compute.id = 1;
            compute.hostId = "ef32e32d";
            compute.efiBlockId = "9B1E-7DE0";
            compute.domain = domain;

            services.nzbget.enable = true;
            services.nzbget.user = "admin";
            services.nzbget.group = "admin";
            services.nzbhydra2.enable = true;
          }
        ];
      };

      nixosConfigurations.compute2 = nixpkgs.lib.nixosSystem
        {
          system = "x86_64-linux";
          modules = [
            sops.nixosModules.sops

            ./modules/common.nix
            ./modules/compute.nix

            {
              compute.id = 2;
              compute.hostId = "7df67865";
              compute.efiBlockId = "0DDD-4E07";
              compute.domain = domain;

              services.radarr.enable = true;
              services.radarr.user = "admin";
              services.radarr.group = "admin";

              services.sonarr.enable = true;
              services.sonarr.user = "admin";
              services.sonarr.group = "admin";

              sops.defaultSopsFile = ./secrets.yaml;
            }
          ];
        };

      nixosConfigurations.compute3 = nixpkgs.lib.nixosSystem
        {
          system = "x86_64-linux";
          modules = [
            ./modules/common.nix
            ./modules/compute.nix

            {
              compute.id = 3;
              compute.hostId = "11dc35bc";
              compute.efiBlockId = "A181-EEC7";
              compute.domain = domain;

              services.plex.enable = true;
              services.plex.user = "admin";
              services.plex.group = "admin";
            }
          ];
        };

      # Map each system in 'nixosConfigurations' to a common
      # deployment description
      deploy.nodes = builtins.mapAttrs
        (
          hostname: attr: {
            inherit hostname;
            fastConnection = true;
            profiles.system = {
              sshUser = "admin";
              user = "root";
              path = deploy-rs.lib."${attr.config.nixpkgs.system}".activate.nixos
                self.nixosConfigurations."${hostname}";
            };
          }
        )
        self.nixosConfigurations;

      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;
    };
}
