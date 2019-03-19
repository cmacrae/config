{ config, pkgs, ... }:
let
  # some nice wallpapers
  # 751150 748463 745470 751188 751223 644594 573093
  # 636345 640342 656431 638670 643158 644744
  wallHaven = "https://wallpapers.wallhaven.cc";
  wallId = "573093";
  wallUrl = "${wallHaven}/wallpapers/full/wallhaven-${wallId}.jpg";
  wall = (builtins.fetchurl "${wallUrl}");
  wallpaper = "${wall}";
in

{
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/cmacrae/dev/nix/thinkpad/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  imports = [
    # Shared
    ../common.nix
    (import ../users.nix {
      wallpaper = "${wall}";
      extraPkgs = with pkgs; [ slack ];
      inputs = ''
        input "1:1:AT_Translated_Set_2_keyboard" {
            xkb_layout gb
            xkb_options ctrl:nocaps
        }
        
        input "1739:0:Synaptics_TM3381-002" {
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
          output HDMI-A-2 position 0,0
          output eDP-1 position 320,1440
        }
      '';
    })

    # Sys Specific
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.checkJournalingFS = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "zfs" ];

  powerManagement.enable = true;

  networking = {
    hostId = "9938e3e0";
    hostName = "thinkpad";
    networkmanager.enable = true;
  };

  services.openvpn.servers.moo = {
    autoStart = false;
    config = "config /home/cmacrae/dev/nix/thinkpad/moo.ovpn";
    up = "echo nameserver $nameserver | ${pkgs.openresolv}/sbin/resolvconf -m 0 -a $dev";
    down = "${pkgs.openresolv}/sbin/resolvconf -d $dev";
  };

  system.stateVersion = "18.09";
}
