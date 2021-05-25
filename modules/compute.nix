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

        domain = mkOption {
          type = types.str;
          description = "DNS domain for compute nodes.";
        };

        hostId = mkOption {
          type = types.str;
          description = "Unique network host ID for ZFS support.";
        };
      };
    };

    config = {
      # Boot
      boot.cleanTmpDir = true;
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
      boot.extraModulePackages = [];

      # aarch64 emulation
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

      swapDevices = [];

      nix.maxJobs = "auto";
      powerManagement.cpuFreqGovernor = "ondemand";

      # NFS Mounts
      fileSystems."/media" = {
        device = "ds1819.${cfg.domain}:/volume1/media";
        fsType = "nfs";
      };

      # Network
      networking = {
        hostName = "compute${builtins.toString cfg.id}";
        hostId = cfg.hostId;
        domain = cfg.domain;
        dhcpcd.enable = false;
        defaultGateway = "10.0.0.1";
        firewall.enable = false;
        nameservers = [ "10.0.0.2" ];
        interfaces.enp0s25.ipv4.addresses = [
          {
            address = "10.0.10.${builtins.toString cfg.id}";
            prefixLength = 16;
          }
        ];
      };

      # System packages
      environment.systemPackages = with pkgs; [ nfs-utils podman ];

      # nix-serve
      services.nix-serve.enable = true;
      services.nix-serve.secretKeyFile =
        config.sops.secrets."${config.networking.hostName}_store_privatekey".path;
      systemd.services.nix-serve = {
        serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
      };

      # Podman
      virtualisation.podman.enable = true;

      # Consul
      services.consul.enable = true;
      services.consul.webUi = true;
      services.consul.interface.bind = "enp0s25";
      services.consul.extraConfig = {
        server = true;
        datacenter = "pantheon";
        client_addr = "127.0.0.1 10.0.10.${builtins.toString cfg.id}";
      };

      # Nomad
      services.nomad.enable = true;
      services.nomad.enableDocker = false;
      services.nomad.dropPrivileges = false; # for use with podman
      systemd.services.podman.path = mkAfter [ pkgs.zfs ];
      services.nomad.settings = {
        region = "lan";
        datacenter = "pantheon";
        server.enabled = true;
        client.enabled = true;
        plugin_dir = "${pkgs.nomad-driver-podman}/bin";
        plugin.nomad-driver-podman.config.socket_path = "unix://run/podman/podman.sock";
      };
    };
  }
