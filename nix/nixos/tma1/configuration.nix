{ config, pkgs, inputs, ... }: {
  imports = [
    inputs.self.nixosModules.common
    inputs.self.nixosModules.home
    inputs.self.nixosModules.graphical
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.generationsDir.copyKernels = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.extraPrepareConfig = ''
    mkdir -p /boot/efis
    for i in  /boot/efis/*; do mount $i ; done

    mkdir -p /boot/efi
    mount /boot/efi
  '';

  boot.loader.grub.extraInstallCommands = ''
    ESP_MIRROR=$(mktemp -d)
    cp -r /boot/efi/EFI $ESP_MIRROR
    for i in /boot/efis/*; do
     cp -r $ESP_MIRROR/EFI $i
    done
    rm -rf $ESP_MIRROR
  '';

  boot.loader.grub.devices = [
    "/dev/disk/by-id/nvme-WD_BLACK_SN770_2TB_225013801136"
  ];

  fileSystems = {
    "/" = {
      device = "rpool/nixos/root";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

    "/home" = {
      device = "rpool/nixos/home";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

    "/var/lib" = {
      device = "rpool/nixos/var/lib";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

    "/var/log" = {
      device = "rpool/nixos/var/log";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

    "/boot" = {
      device = "bpool/nixos/root";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

    "/boot/efis/nvme-WD_BLACK_SN770_2TB_225013801136-part1" = {
      device = "/dev/disk/by-uuid/4A13-A7B7";
      fsType = "vfat";
    };

    "/boot/efi" = {
      device = "/boot/efis/nvme-WD_BLACK_SN770_2TB_225013801136-part1";
      fsType = "none";
      options = [ "bind" ];
    };

    # NFS Mounts
    "/media" = {
      device = "ds1819.cmacr.ae:/volume1/media";
      fsType = "nfs";
    };
  };

  services.zfs.autoScrub.enable = true;

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  # Network
  networking = {
    hostName = "tma1";
    hostId = "891e0f7e";
    firewall.enable = false;
  };

  # System packages
  environment.systemPackages = with pkgs; [ nfs-utils ];

  users.users.cmacrae.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI0ynIFxGh/vtMnReWNA0m0JVQHuP72vi3+jOUDvWZMU+rDX7uljyw8wAsD5u4D5G5GlDp+A0kUo2ASk+NMvz55885woLix/q7P63meeOKOepteIzwdHP6ZYdEzjlLZSCinvf9bumMyiTzqvA/cEFgmUfCz3LEQ9qzoo4b9y/W7J84cUJBTascE3VU6pdG3AIl7wR5VnXu6USuEQl/XVAPUV9y5w+7lwIfBLDXp4DaHnsP7Xc8gTovb/CpsLk7pknd0hPaIFsqTAUmVnplDxjSo/3E+MeCFbzqqt42HBCVQj+CHgwhsqIawll4B1FwnULJAiWhqFAzG6emprEYqN3x" ];


  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/d6/wallhaven-d6mg33.png";
    sha256 = "01vhwfx2qsvxgcrhbyx5d0c6c0ahjp50qy147638m7zfinhk70vx";
  };

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
}
