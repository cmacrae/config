{ config, lib, pkgs, ... }:
let
  homeDir = builtins.getEnv("HOME");
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/release-19.09.tar.gz;
  cfg = config.local.darwin;

in with lib;
{
  imports = [ ../modules/home.nix "${home-manager}/nix-darwin" ];

  options = {
    local.darwin.machine = mkOption {
      type = types.str;
      description = "Target system to build.";
    };
  };

  config = {
    system.stateVersion = 4;
    nix.maxJobs = 8;
    nix.buildCores = 0;
    nix.package = pkgs.nix;

    # Remote builder for linux
    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        hostName = "compute1";
        sshUser = "root";
        sshKey = "${homeDir}/.ssh/id_rsa";
        systems = [ "x86_64-linux" ];
        maxJobs = 16;
      }
      {
        hostName = "compute2";
        sshUser = "root";
        sshKey = "${homeDir}/.ssh/id_rsa";
        systems = [ "x86_64-linux" ];
        maxJobs = 16;
      }
      {
        hostName = "compute3";
        sshUser = "root";
        sshKey = "${homeDir}/.ssh/id_rsa";
        systems = [ "x86_64-linux" ];
        maxJobs = 16;
      }
      {
        hostName = "net1";
        sshUser = "root";
        sshKey = "${homeDir}/.ssh/id_rsa";
        systems = [ "aarch64-linux" ];
        maxJobs = 4;
      }
    ];

    environment.shells = [ pkgs.zsh ];
    programs.bash.enable = false;
    programs.zsh.enable = true;
    environment.darwinConfig = "${homeDir}/dev/config/${cfg.machine}/configuration.nix";

    networking.hostName = cfg.machine;
    
    environment.systemPackages = [ pkgs.gcc ];

    system.defaults = {
      dock = {
        autohide = true;
        mru-spaces = false;
        minimize-to-application = true;
      };

      screencapture.location = "/tmp";

      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXEnableExtensionChangeWarning = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    local.home.alacritty.bindings = [
       { key = "V"; mods = "Command"; action = "Paste"; }
       { key = "C"; mods = "Command"; action = "Copy";  }
       { key = "Q"; mods = "Command"; action = "Quit";  }
       { key = "Q"; mods = "Control"; chars = "\x00"; }
       { key = "N"; mods = "Command"; command = {
           program = "open";
           args = ["-nb" "io.alacritty"];
         };
       }
    ];

    # Recreate /run/current-system symlink after boot
    services.activate-system.enable = true;
  };
}
