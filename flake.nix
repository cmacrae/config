{
  description = "cmacrae's systems configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    home.url = "github:nix-community/home-manager";
    nur.url = "github:nix-community/NUR";
    emacs.url = "github:cmacrae/emacs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    rnix-lsp.url = "github:nix-community/rnix-lsp";
    spacebar.url = "github:cmacrae/spacebar";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";

    # Follows
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home.inputs.nixpkgs.follows = "nixpkgs";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home, nur, emacs, emacs-overlay, rnix-lsp, spacebar, deploy-rs, sops-nix }:
    let
      commonDarwinConfig = [
        ./modules/macintosh.nix
        ./modules/mbsync.nix
        home.darwinModules.home-manager

        {
          nixpkgs.overlays = [
            nur.overlay
            emacs.overlay
            emacs-overlay.overlay
            spacebar.overlay
          ];
        }
      ];

      mailIndicator = mailbox: ''"mu find 'm:/${mailbox}/inbox' flag:unread | wc -l | tr -d \"[:blank:]\""'';

      baseContainer = {
        volumes = [
          "config:/config"
          "/media/downloads:/downloads"
        ];
        extraOptions = [ "--network=host" ];
        environment = {
          PUID = "1001";
          PGID = "1001";
          TZ = "Europe/London";
        };
      };

    in
      {
        darwinConfigurations.macbook = darwin.lib.darwinSystem {
          modules = commonDarwinConfig ++ [
            (
              { pkgs, config, ... }: {
                networking.hostName = "macbook";

                services.spacebar.config.right_shell_command = mailIndicator "fastmail";

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
          modules = commonDarwinConfig ++ [
            (
              { pkgs, ... }: {
                networking.hostName = "workbook";

                services.spacebar.config.right_shell_command = mailIndicator "work";

                home-manager.users.cmacrae = {
                  home.packages = with pkgs; [
                    awscli
                    aws-iam-authenticator
                    vault
                  ];

                  accounts.email.accounts.fastmail.primary = false;
                  accounts.email.accounts.work =
                    let
                      mailAddr = name: domain: "${name}@${domain}";
                    in
                      rec {
                        mu.enable = true;
                        msmtp.enable = true;
                        primary = true;
                        address = mailAddr "calum.macrae" "nutmeg.com";
                        userName = address;
                        realName = "Calum MacRae";

                        mbsync = {
                          enable = true;
                          create = "both";
                          expunge = "both";
                          remove = "both";
                        };

                        imap.host = "outlook.office365.com";
                        smtp.host = "smtp.office365.com";
                        smtp.port = 587;
                        smtp.tls.useStartTls = true;
                        # Office365 IMAP requires an App Password to be created
                        # https://account.activedirectory.windowsazure.com/AppPasswords.aspx
                        passwordCommand = "${pkgs.writeShellScript "work-mbsyncPass" ''
                          ${pkgs.pass}/bin/pass Nutmeg/office.com | ${pkgs.gawk}/bin/awk -F: '/mbsync/{gsub(/ /,""); print$NF}'
                        ''}";
                      };
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
              compute.domain = "cmacr.ae";

              virtualisation.oci-containers.containers = {
                nzbget = baseContainer // {
                  image = "ghcr.io/linuxserver/nzbget:version-v21.0";
                };

                hydra2 = baseContainer // {
                  image = "ghcr.io/linuxserver/nzbhydra2:version-v3.13.1";
                };
              };

              services.nginx = {
                enable = true;

                recommendedGzipSettings = true;
                recommendedOptimisation = true;
                recommendedProxySettings = true;

                virtualHosts."compute1.cmacr.ae".locations = {
                  "/nzbget".proxyPass = "http://compute1:6789";
                  "/hydra2".proxyPass = "http://compute1:5076/hydra2";
                  "/sonarr".proxyPass = "http://compute2:8989/sonarr";
                  "/radarr".proxyPass = "http://compute3:7878/radarr";
                  "/plex".proxyPass = "http://compute3:32400";
                };
              };

            }
          ];
        };

        nixosConfigurations.compute2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules/common.nix
            ./modules/compute.nix

            {
              compute.id = 2;
              compute.hostId = "7df67865";
              compute.efiBlockId = "0DDD-4E07";
              compute.domain = "cmacr.ae";

              virtualisation.oci-containers.containers = {
                sonarr = baseContainer // {
                  image = "ghcr.io/linuxserver/sonarr";
                  volumes = [
                    "config:/config"
                    "/media/downloads:/downloads"
                    "/media/tv:/tv"
                  ];
                };
              };
            }
          ];
        };

        nixosConfigurations.compute3 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules/common.nix
            ./modules/compute.nix

            {
              compute.id = 3;
              compute.hostId = "11dc35bc";
              compute.efiBlockId = "A181-EEC7";
              compute.domain = "cmacr.ae";

              virtualisation.oci-containers.containers = {
                radarr = baseContainer // {
                  image = "ghcr.io/linuxserver/radarr";
                  volumes = [
                    "config:/config"
                    "/media/downloads:/downloads"
                    "/media/movies:/movies"
                  ];
                };

                plex = {
                  image = "plexinc/pms-docker";
                  volumes = [
                    "config:/config"
                    "/media/movies:/data/movies"
                    "/media/tv:/data/tv"
                  ];
                  extraOptions = [ "--network=host" ];
                  environment = {
                    HOSTNAME = "plex.cmacr.ae";
                    TZ = "Europe/London";
                    PLEX_UID = "1001";
                    PLEX_GID = "1001";
                  };
                };
              };
            }
          ];
        };

        # Map each system in 'nixosConfigurations' to a common
        # deployment description
        deploy.nodes = (
          builtins.mapAttrs (
            hostname: attr: {
              inherit hostname;
              fastConnection = true;
              profiles = {
                system = {
                  sshUser = "admin";
                  user = "root";
                  path = deploy-rs.lib."${attr.config.nixpkgs.system}".activate.nixos
                    self.nixosConfigurations."${hostname}";
                };
              };
            }
          ) self.nixosConfigurations
        );

        checks = builtins.mapAttrs
          (system: deployLib: deployLib.deployChecks self.deploy)
          deploy-rs.lib;
      };
}
