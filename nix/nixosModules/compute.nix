{ config, pkgs, lib, ... }:

let
  cfg = config.compute;

in
with pkgs.lib; {
  options = {
    compute = {

      efiBlockId = mkOption {
        type = types.str;
        description = "EFI block device ID to map in filesystems configuration.";
      };

      id = mkOption {
        type = types.int;
        default = 0;
        description = ''
          Numerical ID to assign to each compute node.
          This will be used in the hostname and static IP address assignment.
        '';
      };

      hostId = mkOption {
        type = types.str;
        description = "Unique network host ID for ZFS support.";
      };
    };
  };

  config = {
    # Boot
    boot.tmp.cleanOnBoot = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub.zfsSupport = true;
    boot.loader.grub.copyKernels = true;
    boot.loader.grub.device = "nodev";
    boot.loader.efi.efiSysMountPoint = "/boot";
    boot.initrd.checkJournalingFS = false;
    boot.supportedFilesystems = [ "zfs" ];
    boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    fileSystems."/" =
      {
        device = "rpool/root";
        fsType = "zfs";
      };

    fileSystems."/home" =
      {
        device = "rpool/home";
        fsType = "zfs";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/${cfg.efiBlockId}";
        fsType = "vfat";
      };

    powerManagement.cpuFreqGovernor = "ondemand";

    # NFS Mounts
    fileSystems."/media" = {
      device = "ds1819.${config.networking.domain}:/volume1/media";
      fsType = "nfs";
    };

    # Network
    networking = {
      inherit (cfg) hostId;
      hostName = "compute${builtins.toString cfg.id}";
      firewall.enable = false;
    };

    # System packages
    environment.systemPackages = with pkgs; [ nfs-utils ];
  };
}
