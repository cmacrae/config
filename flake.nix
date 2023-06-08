{
  description = "cmacrae's systems configuration";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    darwin.url = github:lnl7/nix-darwin;
    home.url = github:nix-community/home-manager;
    nur.url = github:nix-community/NUR;
    rnix-lsp.url = github:nix-community/rnix-lsp;
    lollypops.url = github:pinpox/lollypops;
    emacs.url = github:nix-community/emacs-overlay;

    # Follows
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home.inputs.nixpkgs.follows = "nixpkgs";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    lollypops.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, nixpkgs, darwin, home, lollypops, ... }@inputs:
    let
      domain = "cmacr.ae";

      commonLinuxConfig = [
        ./bases/common.nix

        home.nixosModules.home-manager
        lollypops.nixosModules.lollypops
        {
          nix.gc.automatic = true;
          nix.gc.dates = "weekly";
          nix.gc.options = "--delete-older-than 14d";

          security.sudo.enable = true;
          security.sudo.wheelNeedsPassword = false;

          lollypops.secrets.default-cmd = "pass";
          lollypops.secrets.cmd-name-prefix = "Tech/nix-secrets/";
          lollypops.deployment = {
            sudo.enable = true;
            ssh.user = "admin";
          };
        }
      ];

      commonDarwinConfig = [
        ./bases/macintosh.nix
        ./bases/common.nix
        ./bases/home.nix

        home.darwinModules.home-manager

        {
          nix.nixPath = with inputs; [{ inherit darwin; }];
          nixpkgs.overlays = with inputs;
            [
              nur.overlay
              emacs.overlays.emacs
              emacs.overlays.package
            ];
        }
      ];

    in
    {
      darwinConfigurations.air = darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        modules = commonDarwinConfig ++ [
          (
            { pkgs, config, ... }: {
              networking.hostName = "air";

              nix.distributedBuilds = true;
              nix.buildMachines =
                pkgs.lib.forEach (pkgs.lib.range 1 3) (n:
                  {
                    hostName = "compute${builtins.toString n}";
                    sshUser = "admin";
                    systems = [ "aarch64-linux" "x86_64-linux" ];
                    maxJobs = 16;
                  }
                );

              homebrew.casks = [
                "ableton-live-suite"
                "obs"
                "spotify"
              ];
            }
          )
        ];
      };

      darwinConfigurations.workbook = darwin.lib.darwinSystem rec {
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

                  # k8s
                  kind
                  kubectl
                  # kubectx
                  # kubeval
                  # kube-prompt
                  kubernetes-helm
                  kustomize
                ];
              };

              homebrew.casks = [
                "docker"
                "jiggler"
              ];
            }
          )
        ];
      };

      nixosConfigurations.net1 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = commonLinuxConfig ++ [
          ./bases/net1.nix
          ./bases/server.nix

          {
            lollypops.secrets = {
              files = {
                "net1/wireguard-privatekey" = { };
                "net1/acme-dnsimple-envfile" = { };
              };
            };
          }
        ];
      };

      nixosConfigurations.compute1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = commonLinuxConfig ++ [
          ./bases/compute.nix
          ./bases/server.nix

          ({ pkgs, config, ... }: {
            compute.id = 1;
            compute.hostId = "ef32e32d";
            compute.efiBlockId = "9B1E-7DE0";
            compute.domain = domain;

            services.nzbget.enable = true;
            services.nzbget.user = "admin";
            services.nzbget.group = "admin";
          })
        ];
      };

      nixosConfigurations.compute2 = nixpkgs.lib.nixosSystem
        {
          system = "x86_64-linux";
          modules = commonLinuxConfig ++ [
            ./bases/compute.nix
            ./bases/server.nix

            ({ config, ... }: {
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

              services.prowlarr.enable = true;

              services.bazarr.enable = true;
              services.bazarr.user = "admin";
              services.bazarr.group = "admin";
            })
          ];
        };

      nixosConfigurations.compute3 = nixpkgs.lib.nixosSystem
        {
          system = "x86_64-linux";
          modules = commonLinuxConfig ++ [
            ./bases/compute.nix
            ./bases/server.nix

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

      apps."aarch64-darwin".default = lollypops.apps."aarch64-darwin".default { configFlake = self; };
    };
}
