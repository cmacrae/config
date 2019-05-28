{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;
in
{
imports = [ ../lib/home.nix "${home-manager}/nix-darwin" ];

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
