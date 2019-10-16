{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/release-19.09.tar.gz;
in
{
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/cmacrae/dev/nix/imac/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  imports = [
    "${home-manager}/nixos"
    ../lib/home.nix

    (import ../lib/desktop.nix {
      inputs = ''
        input "1452:615:Apple_Inc._Magic_Keyboard" {
            xkb_layout gb
            xkb_variant mac
            xkb_options ctrl:nocaps
        }
        
        input "1452:613:Apple_Inc._Magic_Trackpad_2" {
            pointer_accel 0.7
            tap enabled
            dwt enabled
            natural_scroll enabled
        }
      '';

      extraSwayConfig = ''
        bindsym $mod+Print exec slurp | grim -g - - | wl-copy

        output eDP-1 position 1920,30
        output DP-2 position 0,1080
        output DP-3 position 0,0

        workspace 1 output DP-2
        workspace 2 output eDP-1
        workspace 3 output DP-3
        workspace 5 output eDP-1
        workspace 6 output eDP-1
      '';
    })

    # Sys Specific
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.initrd.checkJournalingFS = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "zfs" ];
  hardware.enableAllFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  networking = {
    hostId = "60f7ad36";
    hostName = "imac";
    domain = "cmacr.ae";
    networkmanager.enable = true;
  };

  system.stateVersion = "19.09";
}
