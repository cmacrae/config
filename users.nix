{ wallpaper, inputs, outputs, extraConfig, extraPkgs }:
{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;

  url = "https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz";
  waylandOverlay = (import (builtins.fetchTarball url));

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

  # systemd service checker for waybar
  waycheck = pkgs.writeShellScriptBin "waycheck"
  (builtins.readFile (pkgs.substituteAll {
    src = ./scripts/waycheck.sh;
    jq = "${pkgs.jq}/bin/jq";
    grep = "${pkgs.gnugrep}/bin/grep";
    systemctl = "${pkgs.systemd}/bin/systemctl";
    })
  );
in
{
  nixpkgs.overlays = [ waylandOverlay ];

  imports = [ "${home-manager}/nixos" ];

  users.users.cmacrae = {
    description = "Calum MacRae";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "audio"
      "docker"
      "input"
      "networkmanager"
      "sway"
      "tty"
      "video"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  programs.sway = {
    enable = true;
    extraPackages = []; # handled via home-manager
  };

  # location svc for redshift
  services.avahi.enable = true;
  services.geoclue2.enable = true;

  home-manager.users.cmacrae = {
    home.packages = with pkgs; [
      ansible
      fzf
      git
      gnumake
      gnupg
      jq
      mpv
      pass
      ranger
      ripgrep
      rsync
      usbutils
      vim
      youtube-dl

      # custom scripts
      waycheck # waybar systemd svc checker

      swayidle # idle handling
      swaylock # screen locking
      waybar   # polybar-alike
      grim     # screen image capture
      slurp    # screen are selection tool
      mako     # notification daemon
      wlstream # screen recorder
      kanshi   # dynamic display configuration helper
      imv      # image viewer
      wl-clipboard  # wayland vers of xclip
      redshift-wayland # patched to work with wayland

      xdg_utils     # for xdg_open
      xwayland      # for X apps
      libnl         # waybar wifi
      libpulseaudio # waybar audio
    ] ++ extraPkgs;

    services.redshift = {
      enable = true;
      provider = "geoclue2";
      package = pkgs.redshift-wayland;
    };

    xdg.enable = true;
    xdg.configFile."sway/config" = {
        source = pkgs.substituteAll {
          name = "sway-config";
          src = ./conf.d/sway-config;
          wallpaper = "${wallpaper}";
          inputs = "${inputs}";
          extraConfig = "${extraConfig}";
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
      default-timeout=10000
      progress-color=source #8BA59B00
      group-by=app-name
      sort=-priority
      
      [urgency=high]
      border-color=#FB543FD9
      ignore-timeout=1
      default-timeout=0
      
      [actionable=true]
      border-color=#FAC03BD9
      ignore-timeout=1
      default-timeout=15000
    '';

    xdg.configFile."imv/config".text = ''
      [options]
      background=#1D2021
      overlay_font=DejaVu Sans Mono:14
    '';

    xdg.configFile."waybar/config" = {
      text = (builtins.readFile ./conf.d/waybar.json);
      onChange = "${reloadSway}";
    };

    xdg.configFile."waybar/style.css" = {
      text = (builtins.readFile ./conf.d/waybar.css);
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

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "emacs";
      history = {
        extended = true;
        ignoreDups = true;
      };
      initExtra = ''
        autoload -Uz promptinit && promptinit
        autoload -Uz zutil
        autoload -Uz complist
        autoload -Uz colors && colors

        setopt   correct always_to_end notify
        setopt   nobeep autolist autocd print_eight_bit
        setopt   append_history share_history globdots
        setopt   pushdtohome cdablevars recexact longlistjobs
        setopt   autoresume histignoredups pushdsilent noclobber
        setopt   autopushd pushdminus extendedglob rcquotes
        unsetopt bgnice autoparamslash

        # Prompts
        if [[ ! -n $INSIDE_EMACS ]]; then
            export "PROMPT=
        %{$fg[red]%}$ %{$reset_color%}"
            export "RPROMPT=%{$fg[blue]%}%~%f%b"
        else
            export "PROMPT=
        %{$fg[blue]%}%~ %{$fg[red]%}$ %f%b"
        fi

        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        if [ "$(tty)" = "/dev/tty1" ]; then
           /run/current-system/sw/bin/sway
        fi
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
      mouseAutohide = true;
      audibleBell = false;
      urgentOnBell = true;
      dynamicTitle = true;
      scrollbar = "off";
      font = "DejaVu Sans Mono 11";
      browser = "${pkgs.xdg_utils}/xdg-open";

      # Darktooth
      backgroundColor = "rgba(29, 32, 33)";
      cursorColor = "#D5C4A1";
      cursorForegroundColor = "#1D2021";
      foregroundColor = "#A89984";
      foregroundBoldColor = "#D5C4A1";
      colorsExtra = ''
        # Black, Gray, Silver, White
        color0  = #1D2021
        color8  = #665C54
        color7  = #A89984
        color15 = #FDF4C1

        # Red
        color1  = #FB543F
        color9  = #FB543F

        # Green
        color2  = #95C085
        color10 = #95C085

        # Yellow
        color3  = #FAC03B
        color11 = #FAC03B

        # Blue
        color4  = #0D6678
        color12 = #0D6678
        # Purple
        color5  = #8F4673
        color13 = #8F4673

        # Teal
        color6  = #8BA59B
        color14 = #8BA59B

        # Extra colors
        color16 = #FE8625
        color17 = #A87322
        color18 = #32302F
        color19 = #504945
        color20 = #928374
        color21 = #D5C4A1
      '';
    };

    programs.rofi = {
      enable = true;
      terminal = "${pkgs.termite}/bin/termite";
    };

    programs.browserpass.enable = true;

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
