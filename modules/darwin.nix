{ config, lib, pkgs, ... }:
let
  cfg = config.local.darwin;

  homeDir = builtins.getEnv("HOME");

  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;

  # TODO: [Darwin] Implement yabai config generator
  # TODO: [Darwin] Implement skhd config generator
  # TODO: [Darwin] yabai launchd daemon
  # TODO: [Darwin] skhd launchd daemon
  yabai = pkgs.callPackage ../pkgs/yabai.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks)
      Carbon Cocoa ScriptingBridge;
  };

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
    services.nix-daemon.enable = true;

    # Firefox
    nixpkgs.overlays = [ (import ../overlays/firefox.nix) ];

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
    
    environment.systemPackages = [ pkgs.gcc yabai pkgs.skhd ];

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
       { key = "Q"; mods = "Control"; chars = "\\x11"; }
       { key = "F"; mods = "Alt"; chars = "\\x1bf"; }
       { key = "B"; mods = "Alt"; chars = "\\x1bb"; }
       { key = "Slash"; mods = "Control"; chars = "\\x1f"; }
       { key = "Period"; mods = "Alt"; chars = "\\e-\\e."; }
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
