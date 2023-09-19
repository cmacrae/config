{ config, lib, pkgs, modulesPath, ... }:

{
  boot.initrd.availableKernelModules = [ "virtio_pci" "xhci_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/8fb8aa6c-9480-4d8f-ac8f-f7211ee7192a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/0DA0-25DD";
      fsType = "vfat";
    };

  swapDevices = [ ];

  networking.useDHCP = true;
  nixpkgs.hostPlatform = "aarch64-linux";

  virtualisation.rosetta.enable = true;
}
