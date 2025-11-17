{ inputs, pkgs, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "tma1";
  system.stateVersion = "24.05";

  imports = [
    inputs.disko.nixosModules.disko
    inputs.self.nixosModules.graphical
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Disable on-board wifi interface
  boot.blacklistedKernelModules = [
    "mt7921e"
    "mt7921_common"
    "mt792x_lib"
    "mt76_connac_lib"
    "mt76"
  ];

  # Disable PCIe power management
  # Causes issues with I225-V network controller
  boot.kernelParams = [ "pcie_aspm=off" ];

  # Driver options for igc (Intel I225-V driver)
  # Use legacy interrupt mode instead of MSI-X
  boot.extraModprobeConfig = ''
    options igc IntMode=1
  '';

  # Fix Intel I225-V network dropout issues
  systemd.services.fix-i225v = {
    description = "Disable problematic offload features on Intel I225-V";
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "fix-i225v" ''
        # Disable UDP segmentation offloads that cause issues on I225-V
        ${pkgs.ethtool}/bin/ethtool -K eno1 tx-udp-segmentation off
        ${pkgs.ethtool}/bin/ethtool -K eno1 tx-udp_tnl-segmentation off
        ${pkgs.ethtool}/bin/ethtool -K eno1 tx-udp_tnl-csum-segmentation off
        # Some users also need to disable generic segmentation
        ${pkgs.ethtool}/bin/ethtool -K eno1 gso off || true
        ${pkgs.ethtool}/bin/ethtool -K eno1 tso off || true
      '';
    };
  };

  # Disable on-board bluetooth controller
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{address}=="D8:80:83:33:A0:C6", ENV{DEVTYPE}=="bluetooth", TEST=="power/control", ATTR{power/control}="off"
  '';

  disko.devices.disk.main = {
    type = "disk";
    content.type = "gpt";
    device = "/dev/nvme0n1";

    content.partitions.MBR.type = "EF02";
    content.partitions.MBR.size = "1M";
    content.partitions.MBR.priority = 1;

    content.partitions.ESP.type = "EF00";
    content.partitions.ESP.size = "500M";
    content.partitions.ESP.content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot";
      mountOptions = [ "umask=0077" ];
    };

    content.partitions.root.size = "100%";
    content.partitions.root.content = {
      type = "filesystem";
      format = "ext4";
      mountpoint = "/";
    };
  };

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics.enable32Bit = true;

  networking.firewall.enable = false;

  services.pipewire.wireplumber.extraConfig = {
    "99-disable-scuf-controller" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.nick" = "~SCUF.*"; } ];
          actions.update-props = {
            "device.disabled" = true;
          };
        }
      ];
    };
  };

  stylix.image = builtins.fetchurl {
    url = "https://gruvbox-wallpapers.pages.dev/wallpapers/minimalistic/light/gruv-buildings.png";
    sha256 = "0jh6l3crk49wdsfg88xq8xr26z33nz2jlwscvxlcnpl5qb5nqfm9";
  };

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-light-soft.yaml";

  programs.gamemode.enable = true;
  programs.gamemode.settings = {
    gpu.apply_gpu_optimisations = "accept-responsibility";
    gpu.gpu_device = 1;
    gpu.amd_performance_level = "high";

    custom = {
      start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
      end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
    };
  };
  users.users.cmacrae.extraGroups = [ "gamemode" ];

  programs.steam = {
    enable = true;
  };

  home-manager.users.cmacrae = {
    home.packages = [
      pkgs.bottles
      pkgs.dolphin-emu
    ];

    stylix.targets.mangohud.enable = false;
    programs.mangohud.enable = true;
    programs.mangohud.settings = {
      gamemode = "";
      pci_dev = "0000:03:00.0";
      legacy_layout = false;
      offset_x = 3;
      offset_y = 0;
      gpu_stats = true;
      gpu_temp = true;
      throttling_status = true;
      cpu_stats = true;
      cpu_temp = true;
      fps = true;
      resolution = true;
      hud_compact = true;
      log_duration = 30;
      log_interval = 100;
      fps_limit_method = "late";
      vsync = 0;
      gl_vsync = -1;
      round_corners = 0;
      background_alpha = 0.0;
      alpha = 0.25;
      position = "top-left";
      table_columns = 3;
      font_size = 20;
      fps_sampling_period = 500;
      gpu_color = "ffffff";
      cpu_color = "ffffff";
      fps_value = "30,60";
      fps_color = "ffffff";
      frametime_color = "ffffff";
      vram_color = "ffffff";
      ram_color = "ffffff";
      wine_color = "ffffff";
      engine_color = "ffffff";
      text_color = "ffffff";
      media_player_color = "ffffff";
      network_color = "ffffff";
    };
  };
}
