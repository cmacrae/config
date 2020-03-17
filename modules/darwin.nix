{ config, lib, pkgs, ... }:
let
  cfg = config.local.darwin;

  homeDir = builtins.getEnv("HOME");

  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;

in with lib;
{
  imports = [
    "${home-manager}/nix-darwin"
    ../modules/home.nix
    ../modules/yabai.nix
  ];

  options = {
    local.darwin.machine = mkOption {
      type = types.str;
      description = "Target system to build.";
    };
    local.darwin.skhd.extraBindings = mkOption {
      type = types.str;
      description = "Extra binding configuration for skhd.";
      default = "";
    };
  };

  config = {
    system.stateVersion = 4;
    nix.maxJobs = 8;
    nix.buildCores = 0;
    nix.package = pkgs.nix;
    services.nix-daemon.enable = true;

    nixpkgs.overlays = [ (import ../overlays) ];

    environment.shells = [ pkgs.zsh ];
    programs.bash.enable = false;
    programs.zsh.enable = true;
    environment.darwinConfig = "${homeDir}/dev/config/machines/${cfg.machine}/configuration.nix";

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

      NSGlobalDomain._HIHideMenuBar = true;
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
       { key = "D"; mods = "Alt"; chars = "\\x1bd"; }
       { key = "Slash"; mods = "Control"; chars = "\\x1f"; }
       { key = "Period"; mods = "Alt"; chars = "\\e-\\e."; }
       { key = "N"; mods = "Command"; command = {
           program = "open";
           args = ["-nb" "io.alacritty"];
         };
       }
    ];

    services.skhd.enable = true;
    launchd.user.agents.skhd.serviceConfig.ProgramArguments = [
      "${config.services.skhd.package}/bin/skhd" "-c" "${homeDir}/.config/skhd/skhdrc"
    ];

    home-manager.users.cmacrae.xdg.configFile."skhd/skhdrc" = {
      source = pkgs.substituteAll {
        name = "skhdrc";
        src = ../conf.d/skhd.conf;
        extraBindings = cfg.skhd.extraBindings;
      };
      onChange = ''
        launchctl stop org.nixos.skhd
        launchctl start org.nixos.skhd
      '';
    };

    services.yabai.enable = true;
    services.yabai.enableScriptingAddition = true;

    home-manager.users.cmacrae.xdg.configFile."yabai/yabairc" = {
      executable = true;
      text = builtins.readFile ../conf.d/yabairc.sh;
      onChange = "${homeDir}/.config/yabai/yabairc";
    };

    services.yabai.configPath = "${homeDir}/.config/yabai/yabairc";

    # Recreate /run/current-system symlink after boot
    services.activate-system.enable = true;
  };
}
