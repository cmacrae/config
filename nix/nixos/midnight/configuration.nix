{ config, pkgs, modulesPath, inputs, ... }: {

  imports = [
    inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
    inputs.self.nixosModules.common
    inputs.self.nixosModules.home
    inputs.self.nixosModules.graphical

    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=0
  '';

  boot.initrd.kernelModules = [
    "nvme"
    "usbhid"
    "usb_storage"
    "ext4"
    "dm-snapshot"
  ];

  boot.kernelParams = [ "apple_dcp.show_notch=1" ];

  zramSwap.enable = true;

  hardware.opengl.enable = true;
  hardware.asahi = {
    # TODO: awaiting upstream support for pure-eval solution.
    #       for now, grab it from a temporary webserver rather
    #       than tracking in git
    # peripheralFirmwareDirectory = ./firmware;
    peripheralFirmwareDirectory = builtins.fetchTarball {
      url = "https://65c4a77cf00c00033cf84d2b--eclectic-horse-092596.netlify.app/firmware.tar.gz";
      sha256 = "01swixbj1vyksm8h1m2ppnyxdfl9p7gqaxgagql29bysvngr8win";
    };

    addEdgeKernelConfig = true;
    useExperimentalGPUDriver = true;
    # TODO: how do we manage this purely?
    # experimentalGPUInstallMode = "driver";
    experimentalGPUInstallMode = "replace";
    withRust = true;
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/a636060b-b2e4-4bc4-841b-7531ace6a990";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/80B9-1907";
      fsType = "vfat";
    };

  nixpkgs.hostPlatform.system = "aarch64-linux";
  nixpkgs.overlays = [
    inputs.nixos-apple-silicon.overlays.apple-silicon-overlay
    # (final: prev: { mesa = final.mesa-asahi-edge; })
  ];

  networking.hostName = "midnight";
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  services.logind.powerKey = "ignore";
  services.logind.suspendKey = "ignore";

  lollypops.tasks = [ "rebuild" ];
  lollypops.deployment.local-evaluation = true;
  lollypops.extraTasks.rebuild = {
    dir = ".";
    deps = [ ];
    desc = "Local rebuild: ${config.networking.hostName}";
    cmds = [
      ''
        sudo nixos-rebuild -L switch --impure --flake ${inputs.self}
      ''
    ];
  };

  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/d6/wallhaven-d6mg33.png";
    sha256 = "01vhwfx2qsvxgcrhbyx5d0c6c0ahjp50qy147638m7zfinhk70vx";
  };

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";

  system.stateVersion = "24.05";
}
