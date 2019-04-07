{ config, pkgs, ... }:
{
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/cmacrae/dev/nix/thinkpad/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  imports = [
    (import ../lib/desktop.nix {
      extraPkgs = with pkgs; [ awscli docker-compose kubernetes kubernetes-helm slack ];
      inputs = ''
        input "1:1:AT_Translated_Set_2_keyboard" {
            xkb_layout gb
            xkb_options ctrl:nocaps
        }
        
        input "1739:0:Synaptics_TM3381-002" {
            pointer_accel 0.7
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

      extraConfig = ''
        bindsym $mod+Print exec slurp | grim -g - - | wl-copy
      '';
    })

    # Sys Specific
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.checkJournalingFS = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "zfs" ];

  powerManagement.enable = true;
  services.tlp.enable = true;
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

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

  virtualisation.virtualbox.host.enable = true;
  users.groups.vboxusers.members = [ "cmacrae" ];

  security.sudo.extraConfig = ''
    %wheel	ALL=(root)	NOPASSWD: ${pkgs.systemd}/bin/systemctl * openvpn-moo
  '';

  system.stateVersion = "19.03";
}
