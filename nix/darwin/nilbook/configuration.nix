{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.self.nixosModules.common
    inputs.self.darwinModules.common
    inputs.self.nixosModules.home
    inputs.home-manager.darwinModules.home-manager
    inputs.stylix.darwinModules.stylix
  ];

  networking.hostName = "nilbook";

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "nix-builder";
      system = "aarch64-linux";
      maxJobs = 2;
      sshUser = "cmacrae";
      sshKey = "${config.users.users.cmacrae.home}/.lima/_config/user";
      supportedFeatures = [ "benchmark" "big-parallel" "nixos-test" ];
    }
  ];

  # NOTE: not sure why stylix insists on having an image...
  stylix.image = pkgs.runCommand "stylix-image" { } "mkdir $out";
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";

  homebrew.casks = [ "asana" "loom" "slack" "zoom" ];

  home-manager.users.cmacrae = {
    imports = [ inputs.limani.homeModules.default ];

    home.packages = with pkgs; [
      awscli
      terraform
      terraform-lsp
      terraform-providers.aws
      terragrunt
    ];

    programs.limani.enable = true;
    # TODO: remove once 0.21.0 is in nixpkgs
    programs.limani.package = pkgs.lima-bin.overrideAttrs (o: rec {
      version = "0.21.0";
      src = builtins.fetchurl {
        url = "https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Darwin-arm64.tar.gz";
        sha256 = "sha256-l6BRf/XXL+sw/0E/Xw73XkwHmCZRuy9zJv5fqtsCMtk=";
      };
    });

    programs.limani.vms = {
      podman.config = inputs.limani.vms.podman { inherit pkgs; };

      # builder for aarch64-linux
      nix-builder.configureSsh = true;
      nix-builder.config = {
        vmType = "vz";

        images = [{
          arch = "aarch64";
          location = builtins.fetchurl {
            url = "https://fedora.mirrorservice.org/fedora/linux/releases/39/Cloud/aarch64/images/Fedora-Cloud-Base-39-1.5.aarch64.raw.xz";
            sha256 = "1h5qhgpq3dvblmam6q81jb7b12fklmiax61rvx31xkdas35pr31a";
          };
        }];

        ssh.localPort = 2202;

        containerd.user = false;
        containerd.system = false;

        provision = [{
          mode = "system";
          script = ''
            #! /usr/bin/env bash 
            set -eux -o pipefail
            curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
          '';
        }];

        probes = [{
          script = ''
            #! /usr/bin/env bash
            set -eux -o pipefail
            if ! timeout 30s bash -c "until command -v nix >/dev/null 2>&1; do sleep 3; done"; then
              echo >&2 "nix is not installed yet"
              exit 1
            fi
          '';
          hint = ''See "/var/log/cloud-init-output.log" in the guest'';
        }];
      };

      # nilenv.configureSsh = true;
      # nilenv.config = {
      #   vmType = "vz";

      #   images = [{
      #     arch = "aarch64";
      #     location = builtins.fetchurl {
      #       url = "https://cloud.debian.org/images/cloud/bookworm/20240102-1614/debian-12-genericcloud-arm64-20240102-1614.qcow2";
      #       sha256 = "0ms1wkwqin70c2ffazkqa72sl27jkbb49210qrj4g63czrw8hrxl";
      #     };
      #   }];

      #   ssh.localPort = 2201;

      #   containerd.user = false;
      #   containerd.system = false;

      #   mounts = [
      #     { location = "/tmp/lima"; writable = true; }
      #     { location = "~/src/nilenv"; writable = true; }
      #   ];
      # };
    };
  };
}
