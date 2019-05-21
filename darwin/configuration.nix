{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;
in
{
  imports = [ ../lib/home.nix "${home-manager}/nix-darwin" ];
  users.users.cmacrae.home = "/Users/cmacrae";
  home-manager.users.cmacrae = {
    programs.zsh.initExtra = ''
      if test -n "$IN_NIX_SHELL"; then return; fi

      if [ -z "$__NIX_DARWIN_SET_ENVIRONMENT_DONE" ]; then
          . /nix/store/gy9s3969mgq2flj1mc1zr4ic09hf1fvi-set-environment
      fi
    '';

    programs.fzf.defaultOptions = [
      "--color fg:240,bg:230,hl:33,fg+:241,bg+:221,hl+:33"
      "--color info:33,prompt:33,pointer:166,marker:166,spinner:33"
    ];
  };

  system.stateVersion = 4;
  nix.maxJobs = 8;
  nix.buildCores = 0;
  nixpkgs.config.allowUnfree = true;

  environment.shells = [ pkgs.zsh ];
  environment.darwinConfig = "/Users/cmacrae/dev/nix/darwin/configuration.nix";

  time.timeZone = "Europe/London";

  system.defaults.dock = {
    autohide = true;
    mru-spaces = false;
    minimize-to-application = true;
  };

  system.defaults.screencapture.location = "/tmp";

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    _FXShowPosixPathInTitle = true;
    FXEnableExtensionChangeWarning = false;
  };

  system.defaults.trackpad = {
    Clicking = true;
    TrackpadThreeFingerDrag = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;
}
