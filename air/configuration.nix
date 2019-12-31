{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;
in
{
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/cmacrae/dev/config/air/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  imports = [
    "${home-manager}/nixos"
    ../modules/home.nix
    ../modules/desktop.nix
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.checkJournalingFS = false;
  boot.initrd.kernelModules = [ "fbcon" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "i915.enable_fbc=1"
  ];

  hardware.enableAllFirmware = true;
  hardware.bluetooth.enable = false;

  powerManagement.enable = true;
  services.tlp.enable = true;
  services.logind.extraConfig = "HandlePowerKey=ignore";

  networking = {
    hostName = "air";
    networkmanager.enable = true;
  };

  local.home.alacritty.fontSize = 10;
  local.desktop.sway = {
    inputs = {
      "1452:586:Apple_Inc._Apple_Internal_Keyboard_/_Trackpad" = {
          xkb_layout = "gb";
          xkb_variant = "mac";
          xkb_options = "ctrl:nocaps";
      };

      "1452:586:bcm5974" = {
          tap = "enabled";
          dwt = "enabled";
          natural_scroll = "enabled";
      };
    };

    outputs = [
      {
        eDP-1 = {};
      }
      {
        "HDMI-A-1" = {
          resolution = "1920x1080";
          pos = "0 0";
        };

        eDP-1 = { position = "330 1080"; };
      }
    ];
  };

  system.stateVersion = "19.09";
}
