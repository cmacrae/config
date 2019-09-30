{ inputs ? "", outputs ? "", extraSwayConfig ? "", extraPkgs ? [] }:
{ config, lib, pkgs, ... }:
let
  url = "https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz";

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

  wallpaper = (builtins.fetchurl "https://w.wallhaven.cc/full/ox/wallhaven-ox1om5.jpg");

in
{
  nix.trustedUsers = [ "root" "@wheel" ];

  time.timeZone = "Europe/London";

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;

  nixpkgs.config.allowUnfree = true;
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
    ] ++ extraPkgs;

    services.emacs.enable = true;
    programs.emacs.enable = true;

    xdg.enable = true;
    xdg.configFile."sway/config" = {
        source = pkgs.substituteAll {
          name = "sway-config";
          src = ../conf.d/sway.conf;
          wallpaper = "${wallpaper}";
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
      gtk3.extraCss = ''
        VteTerminal, vte-terminal {
            padding: 15px;
        }
      '';
    };

    programs.chromium = {
      enable = true;
      extensions = [
        "dbepggeogbaibhgnhhndojpepiihcmeb" # vimium
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "naepdomgkenhinolocfifgehidddafch" # browser-pass
      ];
    };

    xdg.configFile."chromium-flags.conf".text = ''
        --force-device-scale-factor=1
    '';

    programs.termite = {
      enable = true;
      clickableUrl = true;
      audibleBell = false;
      urgentOnBell = true;
      dynamicTitle = true;
      scrollbar = "off";
      font = "DejaVu Sans Mono 12";
      browser = "${pkgs.xdg_utils}/bin/xdg-open";
      cursorBlink = "off";

      # Atom One Dark
      backgroundColor = "rgba(40, 44, 52)";
      cursorColor = "#b6bdca";
      cursorForegroundColor = "#282c34";
      foregroundColor = "#abb2bf";
      foregroundBoldColor = "#b6bdca";
      colorsExtra = ''
        # Black, Gray, Silver, White
        color0  = #282c34
        color8  = #545862
        color7  = #abb2bf
        color15 = #c8ccd4

        # Red
        color1  = #e06c75
        color9  = #e06c75

        # Green
        color2  = #98c379
        color10 = #98c379

        # Yellow
        color3  = #e5c07b
        color11 = #e5c07b

        # Blue
        color4  = #61afef
        color12 = #61afef

        # Purple
        color5  = #c678dd
        color13 = #c678dd

        # Teal
        color6  = #56b6c2
        color14 = #56b6c2

        # Extra colors
        color16 = #d19a66
        color17 = #be5046
        color18 = #353b45
        color19 = #3e4451
        color20 = #565c64
        color21 = #b6bdca
      '';
    };

    programs.rofi = {
      enable = true;
      terminal = "${pkgs.termite}/bin/termite";
    };

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
