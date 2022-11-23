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

    # TODO: Move back to official pkg once this is merged
    #       https://github.com/NixOS/nixpkgs/pull/203504
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
            ];
        }
      ];

    in
    {
      darwinConfigurations.macbook = darwin.lib.darwinSystem rec {
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


              nixpkgs.overlays = with inputs; [
                # TODO: Move back to official pkg once this is merged
                #       https://github.com/NixOS/nixpkgs/pull/203504
                (self: super: {
                  yabai-5_0_1 = (import ivar-nixpkgs-yabai-5_0_1 { inherit system; }).yabai;
                })
              ];

              home-manager.users.cmacrae = {
                home.packages = [
                  deploy-rs.defaultPackage.x86_64-darwin
                ];
              };

              homebrew.casks = [ "spotify" ];
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

              nixpkgs.overlays = with inputs; [
                # TODO: Move back to official pkg once this is merged
                #       https://github.com/NixOS/nixpkgs/pull/203504
                (self: super: {
                  yabai-5_0_1 = (import ivar-nixpkgs-yabai-5_0_1 { inherit system; }).yabai;
                })
              ];

              home-manager.users.cmacrae = {
                home.packages = with pkgs; [
                  awscli
                  aws-iam-authenticator
                  aws-vault
                  terraform-docs
                  vault
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
        modules = [
          ./modules/common.nix
          ./modules/net1.nix
          sops.nixosModules.sops

          {
            sops.defaultSopsFile = ./secrets.yaml;
            sops.secrets.net1_wireguard_privatekey = { };
            sops.secrets.net1_acme_dnsimple_envfile = { };
          }
        ];
      };

      nixosConfigurations.compute1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          sops.nixosModules.sops

          ./modules/common.nix
          ./modules/compute.nix

          ({ pkgs, config, ... }: {
            sops.defaultSopsFile = ./secrets.yaml;

            compute.id = 1;
            compute.hostId = "ef32e32d";
            compute.efiBlockId = "9B1E-7DE0";
            compute.domain = domain;

            services.nzbget.enable = true;
            services.nzbget.user = "admin";
            services.nzbget.group = "admin";

            # services.prometheus = {
            #   enable = true;
            #   enableReload = true;
            #   stateDir = "prometheus";
            #   retentionTime = "4w";
            #   webExternalUrl = "http://prometheus.${domain}";
            #   alertmanager.enable = true;
            #   alertmanager.webExternalUrl = "http://alertmanager.${domain}";
            #   alertmanager.configuration = {
            #     receivers = [{
            #       name = "pushover";
            #       pushover_configs = [{
            #         user_key = "secret stuff"; # TODO: How do we get secrets in here?
            #         token = "secret stuff"; # TODO: How do we get secrets in here?
            #       }];
            #     }];

            #     route.receiver = "pushover";
            #   };

            #   alertmanagers = [{
            #     scheme = "http";
            #     static_configs = [{
            #       targets = [
            #         "localhost:9093"
            #       ];
            #     }];
            #   }];

            #   scrapeConfigs = pkgs.lib.mapAttrsToList
            #     (host: _: {
            #       job_name = host;
            #       static_configs = [{
            #         targets = [ "${host}.${domain}:9100" ];
            #       }];
            #     })
            #     self.nixosConfigurations ++ [
            #     {
            #       job_name = "radarr";
            #       static_configs = [{
            #         targets = [
            #           "compute2.${domain}:${builtins.toString config.services.prometheus.exporters.radarr.port}"
            #         ];
            #       }];
            #     }
            #     {
            #       job_name = "sonarr";
            #       static_configs = [{
            #         targets = [
            #           "compute2.${domain}:${builtins.toString config.services.prometheus.exporters.sonarr.port}"
            #         ];
            #       }];
            #     }
            #   ];
            # };

            # sops.secrets.compute1_grafana_admin_password.owner = config.users.users.grafana.name;
            # sops.secrets.compute1_grafana_admin_password.group = config.users.users.grafana.group;

            # services.grafana = {
            #   enable = true;
            #   addr = "0.0.0.0";
            #   domain = "grafana.${domain}";
            #   analytics.reporting.enable = false;
            #   security.adminUser = "cmacrae";
            #   security.adminPasswordFile = config.sops.secrets.compute1_grafana_admin_password.path;
            #   provision.enable = true;

            #   declarativePlugins = with pkgs.grafanaPlugins; [ grafana-piechart-panel ];

            #   provision.datasources = [
            #     {
            #       name = "Prometheus";
            #       type = "prometheus";
            #       isDefault = true;
            #       url = "http://${config.networking.hostName}:${builtins.toString config.services.prometheus.port}";
            #     }
            #     {
            #       name = "Loki";
            #       type = "loki";
            #       url = "http://${config.networking.hostName}:${builtins.toString config.services.loki.configuration.server.http_listen_port}";
            #     }
            #   ];

            #   provision.dashboards =
            #     let
            #       dashboardPkg = { id, version, sha256 }: pkgs.stdenv.mkDerivation
            #         rec {
            #           pname = "${id}-${version}-dashboard";
            #           inherit version;
            #           dontUnpack = true;
            #           src = builtins.fetchurl {
            #             url = "https://grafana.com/api/dashboards/${id}/revisions/${version}/download";
            #             inherit sha256;
            #           };
            #           installPhase = ''
            #             mkdir -p $out
            #             cp ${src} $out/${pname}.json
            #           '';
            #         }; in
            #     [
            #       {
            #         name = "Node Exporter";
            #         options.path = dashboardPkg {
            #           id = "1860";
            #           version = "27";
            #           sha256 = "16srb69lhysqvkkwf25d427dzg4p2fxr1igph9j8aj9q4kkrw595";
            #         };
            #       }
            #       {
            #         name = "Radarr";
            #         options.path = dashboardPkg {
            #           id = "12896";
            #           version = "1";
            #           sha256 = "1fqpwp544sc3m0gvnn9cvgiampkwilpp5vizhix2182c120waqih";
            #         };
            #       }
            #       {
            #         name = "Sonarr";
            #         options.path = dashboardPkg {
            #           id = "12530";
            #           version = "2";
            #           sha256 = "0nqnl7vyg0nlskgxskhkyfyn2c0izf2wq5350sg4x8sp1zv1q429";
            #         };
            #       }
            #     ];
            # };

            # services.loki.enable = true;
            # services.loki.configuration = {
            #   auth_enabled = false;
            #   server.http_listen_port = 3100;
            #   server.grpc_listen_port = 9096;
            #   common = rec {
            #     path_prefix = "/var/lib/loki";
            #     storage.filesystem.chunks_directory = "${path_prefix}/chunks";
            #     storage.filesystem.rules_directory = "${path_prefix}/rules";
            #     replication_factor = 1;
            #     ring.instance_addr = "127.0.0.1";
            #     ring.kvstore.store = "inmemory";
            #   };
            #   schema_config.configs = [{
            #     from = "2020-10-24";
            #     store = "boltdb-shipper";
            #     object_store = "filesystem";
            #     schema = "v11";
            #     index.prefix = "index_";
            #     index.period = "24h";
            #   }];
            #   ruler.alertmanager_url = "http://localhost:9093";
            #   analytics.reporting_enabled = false;
            # };
          })
        ];
      };

      nixosConfigurations.compute2 = nixpkgs.lib.nixosSystem
        {
          system = "x86_64-linux";
          modules = [
            sops.nixosModules.sops

            ./modules/common.nix
            ./modules/compute.nix

            ({ config, ... }: {
              sops.defaultSopsFile = ./secrets.yaml;

              compute.id = 2;
              compute.hostId = "7df67865";
              compute.efiBlockId = "0DDD-4E07";
              compute.domain = domain;

              services.radarr.enable = true;
              services.radarr.user = "admin";
              services.radarr.group = "admin";

              sops.secrets.compute2_radarr_exporter_envfile = { };
              # services.prometheus.exporters.radarr.enable = true;
              # services.prometheus.exporters.radarr.enableAdditionalMetrics = true;
              # services.prometheus.exporters.radarr.url = "http://127.0.0.1:7878";
              # services.prometheus.exporters.radarr.credentialsFile = config.sops.secrets.compute2_radarr_exporter_envfile.path;

              services.sonarr.enable = true;
              services.sonarr.user = "admin";
              services.sonarr.group = "admin";

              sops.secrets.compute2_sonarr_exporter_envfile = { };
              # services.prometheus.exporters.sonarr.enable = true;
              # services.prometheus.exporters.sonarr.enableAdditionalMetrics = true;
              # services.prometheus.exporters.sonarr.url = "http://127.0.0.1:8989";
              # services.prometheus.exporters.sonarr.credentialsFile = config.sops.secrets.compute2_sonarr_exporter_envfile.path;

              services.prowlarr.enable = true;
              services.prowlarr.user = "admin";
              services.prowlarr.group = "admin";

              services.bazarr.enable = true;
              services.bazarr.user = "admin";
              services.bazarr.group = "admin";
            })
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
