{
  description = "cmacrae's systems configuration";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    darwin.url = github:lnl7/nix-darwin;
    home.url = github:nix-community/home-manager;
    nur.url = github:nix-community/NUR;
    rnix-lsp.url = github:nix-community/rnix-lsp;
    # TODO: Move back to upstream once features are merged
    # lollypops.url = github:pinpox/lollypops;
    lollypops.url = github:cmacrae/lollypops;
    # lollypops.url = "/Users/cmacrae/src/github.com/cmacrae/lollypops";
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
        lollypops.darwinModules.lollypops

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

      build1Config = [
        ./bases/server.nix

        {
          fonts.fontconfig.enable = false;
          networking.hostName = "build1";
          networking.interfaces.enp0s1.macAddress = "e2:fc:13:e6:cc:aa";
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

              nix.settings.builders = "@/etc/nix/machines";
              nix.settings.builders-use-substitutes = true;
              nix.distributedBuilds = true;
              nix.buildMachines =
                pkgs.lib.forEach (pkgs.lib.range 1 3)
                  (n:
                    {
                      hostName = "compute${builtins.toString n}";
                      sshUser = "admin";
                      systems = [ "x86_64-linux" ];
                      maxJobs = 16;
                    }
                  ) ++
                [{
                  hostName = "build1";
                  sshUser = "admin";
                  systems = [ "aarch64-linux" ];
                  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
                  maxJobs = 16;
                }];

              homebrew.casks = [
                "ableton-live-suite"
                "audacity"
                "chatterino"
                "musicbrainz-picard"
                "obs"
                "splice"
                "spotify"
                "yubico-yubikey-manager"
              ];

              home-manager.users.cmacrae = {
                imports = [ ./modules/tart.nix ];
                launchd.agents.prodSync.enable = true;
                launchd.agents.prodSync.config = {
                  Label = "ae.cmacr.sync";
                  ProgramArguments = [
                    "${pkgs.writeShellScript "prod_sync" ''
                      # allow the OS to fully mount or unmount the drive
                      sleep 5
                      SRC="/Volumes/Sounds"
                      DEST="${config.users.users.cmacrae.home}/Library/Mobile Documents/com~apple~CloudDocs/Music/prod"
                      if [ -d "$SRC" ] && [ -d "$DEST" ]; then
                        ${pkgs.unison}/bin/unison "$SRC" "$DEST" \
                          -batch -ui text -perms 0 -fastcheck true \
                          -ignore 'Path {.fseventsd}' \
                          -ignore 'Regex .Spotlight-V.*' \
                          -ignore 'Path {.Trashes}'
                      else
                        echo "Either source directory $SRC or destination directory $DEST does not exist. Exiting."
                        exit 1
                      fi
                    ''}"
                  ];
                  WatchPaths = [ "/Volumes/Sounds" ];
                  RunAtLoad = false;
                };

                programs.tart.enable = true;
                programs.tart.vms = {
                  build1 = {
                    runAtLoad = true;
                    vmRunArgs = [
                      "--net-bridged=en0"
                      "--no-graphics"
                      "--rosetta=rosetta"
                    ];
                    pkg = (pkgs.stdenv.mkDerivation {
                      name = "build1-vm";
                      version = "0.0.1-alpha";
                      src = builtins.fetchTarball {
                        url = "file:///${config.users.users.cmacrae.home}/build1-vm-pkg.tar.gz";
                        sha256 = "1rqfdggpxaj1vpfxbrz31ckjqw61b383j3izc8q6yb2h8ln7icif";
                      };
                      dontBuild = true;
                      installPhase = ''
                        mkdir -p $out
                        cp -r $src/* $out/
                      '';
                    });
                  };
                };
              };

              lollypops.tasks = [ "rebuild" ];
              lollypops.extraTasks = {
                rebuild = {
                  dir = ".";
                  deps = [ "check-vars" ];
                  desc = "Rebuild configuration of: air";
                  cmds = [
                    ''
                      darwin-rebuild -L switch --flake ${self} 
                    ''
                  ];
                };
              };
            }
          )
        ];
      };

      darwinConfigurations.workbook = darwin.lib.darwinSystem
        rec {
          system = "aarch64-darwin";
          modules = commonDarwinConfig ++ [
            (
              { pkgs, ... }: {
                networking.hostName = "workbook";

                home-manager.users.cmacrae = {
                  programs.gpg.scdaemonSettings.disable-ccid = true;
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

      nixosConfigurations.net1 = nixpkgs.lib.nixosSystem
        {
          system = "aarch64-linux";
          modules = commonLinuxConfig ++ [
            ./bases/net1.nix
            ./bases/server.nix

            {
              lollypops.deployment.local-evaluation = true;
              lollypops.secrets = {
                files = {
                  "net1/wireguard-privatekey" = { };
                  "net1/acme-dnsimple-envfile" = { };
                };
              };

              # Use `nix-build` to rely on build1 VM
              lollypops.tasks = [ "deploy-secrets" "rebuild" ];
              lollypops.extraTasks = {
                bootstrap-builder = {
                  deps = [ "check-vars" ];
                  desc = "Ensure the build VM is running";
                  cmds = [
                    ''
                      { tart list --format json | jq -e '.[]|select(.Name=="build1")|any' > /dev/null; } || \
                      { echo "No VM called 'build1' found..." ; exit 1; }
                    ''
                    ''
                      if tart list --format json \
                         | jq -e '.[]|select(.Name=="build1" and .Running==true)|any' \
                         > /dev/null; then
                        echo "build1 is up...";
                      else
                        echo "booting build1..."
                        launchctl bootstrap gui/$UID ~/Library/LaunchAgents/ae.cmacr.tart-build1.plist

                        count=0
                        max_tries=15

                        echo "Waiting for build1 to come up..."

                        while [ $count -lt $max_tries ]; do
                          if nc -vz build1 22 > /dev/null 2>&1; then
                            echo "Looks like build1 is ready!"
                            exit 0
                          fi

                          count=$((count + 1))
                          sleep 1
                        done

                        echo "Failed after $max_tries attempts."
                        exit 1
                      fi
                    ''
                  ];
                };
                rebuild = {
                  dir = ".";
                  deps = [ "bootstrap-builder" ];
                  desc = "Rebuild configuration of: net1";
                  cmds = [
                    ''
                      nix build -L \
                      ${self}#nixosConfigurations.net1.config.system.build.toplevel && \
                      REAL_PATH=$(realpath ./result) && \
                      nix copy -s --to ssh://admin@net1 $REAL_PATH 2>&1 && \
                      ssh admin@net1 \
                      "sudo nix-env -p /nix/var/nix/profiles/system --set $REAL_PATH && \
                      sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
                    ''
                  ];
                };
              };
            }
          ];
        };

      nixosConfigurations.compute1 = nixpkgs.lib.nixosSystem
        {
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

      nixosConfigurations.build1 = nixpkgs.lib.nixosSystem
        {
          system = "aarch64-linux";
          modules = commonLinuxConfig ++ build1Config ++ [
            ./bases/build1.nix
          ];
        };

      build1-image = (nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = commonLinuxConfig ++ build1Config ++ [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"

          {
            isoImage.isoBaseName = "build1";
            isoImage.appendToMenuLabel = "Nix Build Environment";
            isoImage.makeEfiBootable = true;
            isoImage.makeUsbBootable = true;
          }
        ];
      }).config.system.build.isoImage;

      apps."aarch64-darwin".default = lollypops.apps."aarch64-darwin".default
        { configFlake = self; };
    };
}
