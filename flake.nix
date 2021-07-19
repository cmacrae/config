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
    sops.url = "github:Mic92/sops-nix";

    # Follows
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home.inputs.nixpkgs.follows = "nixpkgs";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs";
    sops.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home, deploy-rs, sops, ... }@inputs:
    let
      domain = "cmacr.ae";

      computeParticipants = 3;
      commonComputeConfig = [
        {
          sops.defaultSopsFile = ./secrets.yaml;

          services.consul.extraConfig.bootstrap_expect = computeParticipants;
          services.nomad.settings.server.bootstrap_expect = computeParticipants;
          services.consul.extraConfig.retry_join =
            nixpkgs.lib.forEach (nixpkgs.lib.range 1 computeParticipants)
              (n: "10.0.10.${toString n}");
        }
      ];

      commonDarwinConfig = [
        ./modules/macintosh.nix
        ./modules/mbsync.nix
        home.darwinModules.home-manager

        {
          nixpkgs.overlays = with inputs; [
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
                  pkgs.lib.forEach (pkgs.lib.range 1 computeParticipants) (
                    n:
                      {
                        hostName = "compute${builtins.toString n}";
                        sshUser = "root";
                        sshKey = "${config.users.users.cmacrae.home}/.ssh/id_rsa";
                        systems = [ "aarch64-linux" "x86_64-linux" ];
                        maxJobs = 16;
                      }
                  );

                # Personal local network caches
                nix.binaryCaches = [
                  "http://compute1.cmacr.ae:5000"
                  "http://compute2.cmacr.ae:5000"
                  "http://compute3.cmacr.ae:5000"
                ];

                nix.binaryCachePublicKeys = [
                  "compute1.cmacr.ae-1:IOsUhW3iV0YqgaRNxnBROk8w586zC78jdp/fof5pPl4="
                  "compute2.cmacr.ae-1:mBaXeUjr9z7bx8bnzrROjd/vI/q461A/TFtYHqeD3G8="
                  "compute3.cmacr.ae-1:0Xb2N8z/co9+PDO2rx8ix9whG4itRp8TvmPBzD7Pzr4="
                ];

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
            sops.nixosModules.sops

            {
              sops.defaultSopsFile = ./secrets.yaml;
              sops.secrets.net1_wireguard_privatekey = {};
            }
          ];
        };

        nixosConfigurations.compute1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonComputeConfig ++ [
            ./modules/common.nix
            ./modules/compute.nix
            sops.nixosModules.sops

            {
              compute.id = 1;
              compute.hostId = "ef32e32d";
              compute.efiBlockId = "9B1E-7DE0";
              compute.domain = domain;

              sops.secrets.compute1_store_privatekey.owner = "nix-serve";

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

        nixosConfigurations.compute2 = nixpkgs.lib.nixosSystem
          {
            system = "x86_64-linux";
            modules = commonComputeConfig ++ [
              ./modules/common.nix
              ./modules/compute.nix
              sops.nixosModules.sops

              {
                compute.id = 2;
                compute.hostId = "7df67865";
                compute.efiBlockId = "0DDD-4E07";
                compute.domain = domain;

                sops.secrets.compute2_store_privatekey.owner = "nix-serve";

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

        nixosConfigurations.compute3 = nixpkgs.lib.nixosSystem
          {
            system = "x86_64-linux";
            modules = commonComputeConfig ++ [
              ./modules/common.nix
              ./modules/compute.nix
              sops.nixosModules.sops

              {
                compute.id = 3;
                compute.hostId = "11dc35bc";
                compute.efiBlockId = "A181-EEC7";
                compute.domain = domain;

                sops.secrets.compute3_store_privatekey.owner = "nix-serve";

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
