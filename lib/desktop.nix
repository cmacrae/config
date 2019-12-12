{ inputs ? "", outputs ? "", extraSwayConfig ? "", extraPkgs ? [] }:
{ config, lib, pkgs, ... }:
let
  # NOTE
  # - $SWAYSOCK unavailable
  # - $(sway --get-socketpath) doesn't work
  # A bit hacky, but since we always know our uid
  # this works consistently
  reloadSway = ''
    echo "Reloading sway"
    swaymsg -s \
    $(find /run/user/''${UID}/ \
      -name "sway-ipc.''${UID}.*.sock") \
    reload
  '';

  wallpaperCmd = "${pkgs.wallutils}/bin/setrandom -v ${pkgs.pantheon.elementary-wallpapers}/share/backgrounds/elementary";

in {
  nix.trustedUsers = [ "root" "@wheel" ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;

  environment.systemPackages = with pkgs; [ file vim ];
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      iosevka
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts
      dina-font
      proggyfonts
      emacs-all-the-icons-fonts
    ];
  };

  services.illum.enable = true;

  services.openssh.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  security.sudo.enable = true;
  security.rtkit.enable = true;

  imports = [ ./home.nix ];

  users.users.cmacrae = {
    description = "Calum MacRae";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "audio"
      "cdrom"
      "docker"
      "input"
      "libvirtd"
      "networkmanager"
      "sway"
      "tty"
      "video"
      "wheel"
    ];
  };

  programs.sway = {
    enable = true;
    extraPackages = []; # handled via home-manager
  };

  systemd.user = {
    targets.sway-session = {
      description = "sway compositor session";
      documentation = ["man:systemd.special(7)"];
      bindsTo = ["graphical-session.target"];
      wants = ["graphical-session-pre.target"];
      after = ["graphical-session-pre.target"];
    };

    services.wallpaper = {
      description = "Timed random wallpapers";
      wantedBy = ["sway-session.target"];
      partOf = ["graphical-session.target"];
      startAt = "*:0/15";
      serviceConfig = {
        ExecStart = wallpaperCmd;
      };
    };
  };

  home-manager.users.cmacrae = {
    home.packages = with pkgs; [
      swayidle # idle handling
      swaylock # screen locking
      waybar   # polybar-alike
      grim     # screen image capture
      slurp    # screen are selection tool
      mako     # notification daemon
      kanshi   # dynamic display configuration helper
      imv      # image viewer
      wf-recorder # screen recorder
      wl-clipboard  # wayland vers of xclip

      xdg_utils     # for xdg_open
      xwayland      # for X apps
      libnl         # waybar wifi
      libpulseaudio # waybar audio

      spotify
    ] ++ extraPkgs;

    xdg.enable = true;
    xdg.configFile."sway/config" = {
        source = pkgs.substituteAll {
          name = "sway-config";
          src = ../conf.d/sway.conf;
          wallpaperCmd = wallpaperCmd;
          inputs = "${inputs}";
          extraConfig = "${extraSwayConfig}";
        };
        onChange = "${reloadSway}";
    };

    xdg.configFile."kanshi/config".text = "${outputs}";

    xdg.configFile."mako/config".text = ''
      font=DejaVu Sans 11
      text-color=#1D2021D9
      background-color=#8BA59BD9
      border-color=#0D6678D9
      border-size=3
      max-visible=3
      default-timeout=15000
      progress-color=source #8BA59B00
      group-by=app-name
      sort=-priority

      [urgency=high]
      border-color=#FB543FD9
      ignore-timeout=1
      default-timeout=0
    '';

    xdg.configFile."imv/config".text = ''
      [options]
      background=#1D2021
      overlay_font=DejaVu Sans Mono:14
    '';

    xdg.configFile."waybar/config" = {
      onChange = "${reloadSway}";
      text = builtins.toJSON (
        import ./waybar-config.nix {
          inherit (config.networking) hostName;
          inherit pkgs;
          inherit lib;
        }
      );
    };

    xdg.configFile."waybar/style.css" = {
      text = (builtins.readFile ../conf.d/waybar.css);
      onChange = "${reloadSway}";
    };

    gtk = {
      enable = true;
      font.package = pkgs.dejavu_fonts;
      font.name = "DejaVu Sans 10";
      theme.package = pkgs.pantheon.elementary-gtk-theme;
      theme.name = "elementary";
      iconTheme.package = pkgs.pantheon.elementary-icon-theme;
      iconTheme.name = "elementary";
      gtk3.extraConfig = { gtk-application-prefer-dark-theme = true; };
    };

    programs.chromium = {
      enable = true;
      extensions = [
        "dbepggeogbaibhgnhhndojpepiihcmeb" # vimium
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "naepdomgkenhinolocfifgehidddafch" # browser-pass
        "bhloflhklmhfpedakmangadcdofhnnoh" # Google Earth view
      ];
    };

    xdg.configFile."chromium-flags.conf".text = ''
      --force-device-scale-factor=1
    '';

    programs.rofi.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';
    };
  };
}
