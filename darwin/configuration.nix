{ config, lib, pkgs, ... }:
let
  homeDir = "/Users/cmacrae";
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;
  buildslave = pkgs.writeShellScriptBin "start-nixops-buildslave"
    (builtins.readFile
      (builtins.fetchurl https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)
    );
in
{
  imports = [ ../lib/home.nix "${home-manager}/nix-darwin" ];

  system.stateVersion = 4;
  nix.maxJobs = 8;
  nix.buildCores = 0;
  nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

  # Remote builder for linux
  services.nix-daemon.enable = true;
  nix.distributedBuilds = true;
  nix.buildMachines = [
    # {
    #   hostName = "nix-docker-build-slave";
    #   sshUser = "root";
    #   sshKey = "${homeDir}/.nix-docker-build-slave/insecure_rsa";
    #   systems = [ "x86_64-linux" ];
    #   maxJobs = 2;
    # }
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
  programs.zsh.enable = true;
  environment.darwinConfig = "${homeDir}/dev/nix/darwin/configuration.nix";
  environment.systemPackages = [ buildslave pkgs.gcc ];

  time.timeZone = "Europe/London";

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
