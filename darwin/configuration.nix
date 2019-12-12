{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/release-19.09.tar.gz;
in
{
  imports = [ ../lib/home.nix "${home-manager}/nix-darwin" ];

  system.stateVersion = 4;
  nix.maxJobs = 8;
  nix.buildCores = 0;
  nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

  # Remote builder for linux
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "compute1";
      sshUser = "root";
      sshKey = "${builtins.getEnv("HOME")}/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "compute2";
      sshUser = "root";
      sshKey = "${builtins.getEnv("HOME")}/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "compute3";
      sshUser = "root";
      sshKey = "${builtins.getEnv("HOME")}/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    {
      hostName = "net1";
      sshUser = "root";
      sshKey = "${builtins.getEnv("HOME")}/.ssh/id_rsa";
      systems = [ "aarch64-linux" ];
      maxJobs = 4;
    }
  ];

  environment.shells = [ pkgs.zsh ];
  programs.bash.enable = false;
  programs.zsh.enable = true;
  environment.darwinConfig = "${builtins.getEnv("HOME")}/dev/nix/darwin/configuration.nix";
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

  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;
}
