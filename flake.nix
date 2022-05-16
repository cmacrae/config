{
  description = "cmacrae's systems configuration";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    darwin.url = github:lnl7/nix-darwin;
    home.url = github:nix-community/home-manager;
    nur.url = github:nix-community/NUR;
    emacs.url = github:cmacrae/emacs;
    emacs-overlay.url = github:nix-community/emacs-overlay;
    rnix-lsp.url = github:nix-community/rnix-lsp;
    deploy-rs.url = github:serokell/deploy-rs;
    sops.url = github:Mic92/sops-nix;
    mgc.url = "/Users/cmacrae/src/github.com/cmacrae/mgc";

    # Follows
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home.inputs.nixpkgs.follows = "nixpkgs";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs";
    sops.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home, deploy-rs, sops, mgc, ... }@inputs:
    let
      domain = "cmacr.ae";

      commonDarwinConfig = [
        ./modules/macintosh.nix
        home.darwinModules.home-manager

        {
          nixpkgs.overlays = with inputs; [
            nur.overlay
            emacs.overlay
            emacs-overlay.overlay
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
        system = "x86_64-darwin";
        modules = commonDarwinConfig ++ [
          (
            { pkgs, ... }: {
              networking.hostName = "workbook";

              home-manager.users.cmacrae = {
                home.packages = with pkgs; [
                  argocd
                  awscli
                  aws-iam-authenticator
                  terraform-docs
                  vault
                ];
              };
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
            mgc.nixosModules.mgc
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
              sops.secrets.compute2_mgc_env_file = { };

              services.mgc.enable = true;
              services.mgc.user = "admin";
              services.mgc.group = "admin";
              services.mgc.package = mgc.packages.x86_64-linux.mgc;
              services.mgc.deleteFiles = true;
              services.mgc.ignoreTag = "keep";
              services.mgc.schedule = ''"0 3 * * *"'';
              # TODO: Set to result
              services.mgc.environmentFile = "/run/secrets/compute2_mgc_env_file";
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
