{ config, pkgs, ... }:
let
  # some nice wallpapers
  # 751150 748463 745470 751188 751223 644594 573093
  wallHaven = "https://wallpapers.wallhaven.cc";
  wallId = "573093";
  wallUrl = "${wallHaven}/wallpapers/full/wallhaven-${wallId}.jpg";
  wall = (builtins.fetchurl "${wallUrl}");
  wallpaper = "${wall}";
in

{
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/cmacrae/dev/nix/air/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  imports = [
     # Shared
     ../common.nix
    (import ../users.nix {
      wallpaper = "${wall}";
      extraPkgs = [];
      inputs = ''
        input "1452:586:Apple_Inc._Apple_Internal_Keyboard_/_Trackpad" {
            xkb_layout gb
            xkb_variant mac
            xkb_options ctrl:nocaps
        }
        
        input "1452:586:bcm5974" {
            tap enabled
            dwt enabled
            natural_scroll enabled
        }
      '';

      outputs = ''
        {
          output eDP-1
        }
        {
          output HDMI-A-1 resolution 1920x1080 pos 0 0
          output eDP-1 position 330 1080
        }
      '';
      extraConfig = "";
    })

     # Sys Specific
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

  networking = {
    hostName = "air";
    networkmanager.enable = true;
  };

  system.stateVersion = "18.09";
}
