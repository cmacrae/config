{ config
, pkgs
, inputs
, ...
}:

let
  inherit (pkgs.lib) optionals;
  isMacBook = builtins.elem "apple_dcp.show_notch=1" config.boot.kernelParams;
in

{
  imports = [ inputs.stylix.nixosModules.stylix ];

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Compat
  programs.dconf.enable = true;
  security.polkit.enable = true;
  fonts.enableDefaultPackages = true;

  # Bluetooth
  # NOTE to self:
  # bluetoothctl:
  # power on
  # agent on
  # default-agent
  # scan on
  # pair XX:XX:XX:XX:XX:XX
  # trust XX:XX:XX:XX:XX:XX
  # connect XX:XX:XX:XX:XX:XX
  hardware.bluetooth.enable = true;

  # Screen
  hardware.brillo.enable = isMacBook;

  # Yubikey
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Compositor
  programs.hyprland.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet -r --cmd ${pkgs.hyprland}/bin/Hyprland";
        user = "greeter";
      };
    };
  };

  security.pam.services.waylock.text = ''
    auth include system-auth
  '';

  qt.enable = true;

  # Storage Management
  services.udisks2.enable = true;

  stylix.enable = true;
  stylix.fonts = {
    serif.name = "Roboto Serif";
    serif.package = pkgs.roboto-serif;
    sansSerif.name = "Roboto Sans";
    sansSerif.package = pkgs.roboto-serif;
    monospace.name = "Roboto Mono";
    monospace.package = pkgs.roboto-mono;
    emoji.package = pkgs.noto-fonts-emoji;
    emoji.name = "Noto Color Emoji";

    sizes.terminal = 10;
    sizes.applications = 10;
  };

  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 20;
  };

  home-manager.users.cmacrae =
    let
      theme = {
        inherit (config.lib.stylix.colors)
          base00
          base01
          base02
          base03
          base04
          base05
          base08
          base09
          base0A
          base0B
          base0C
          base0D
          ;
      };

      cssWithTheme = file: pkgs.lib.concatStringsSep "\n"
        (pkgs.lib.mapAttrsToList
          (name: value: "@define-color ${name} #${value};")
          theme) + builtins.readFile file;
    in
    {
      imports = [ inputs.self.homeModules.swaync ];

      stylix.targets.gtk.enable = true;
      stylix.targets.foot.enable = true;
      stylix.targets.waybar.enable = false;
      stylix.targets.hyprland.enable = false;

      systemd.user.services.polkit-kde-auth-agent = {
        Unit.PartOf = [ "graphical-session.target" ];
        Unit.After = [ "graphical-session-pre.target" ];

        Service = {
          ExecStart = "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
          BusName = "org.kde.polkit-kde-authentication-agent-1";
          Slice = "background.slice";
          TimeoutSec = "5sec";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = [ "hyprland-session.target" ];
        };
      };

      home.packages = with pkgs; [
        _1password-gui
        chatterino2
        discord
        emacs-all-the-icons-fonts
        gnome-disk-utility
        libnotify
        pantheon.elementary-calculator
        pinentry
        playerctl
        qpwgraph
        spotify
        streamlink
        streamlink-twitch-gui-bin
        wayland-utils
        wev
        wireplumber
        wl-clipboard
        xdg-utils
        xfce.thunar
        yubioath-flutter
      ];

      gtk = {
        enable = true;
        iconTheme = {
          package = pkgs.rose-pine-icon-theme;
          name = "rose-pine";
        };
      };

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        systemd.variables = [ "--all" ];
        settings = {
          monitor = if isMacBook then "eDP-1,highres,auto,1.600000" else "DP-1,3840x2160@240,auto,1";

          input = {
            follow_mouse = 1;
            sensitivity = "0.65";
            touchpad.natural_scroll = true;
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          general = {
            gaps_in = 5;
            gaps_out = 12;
            border_size = 3;
            "col.active_border" = "0xff${theme.base0D}";
            "col.inactive_border" = "0xff${theme.base03}";
          };

          decoration = {
            rounding = 0;
          };

          animations = {
            enabled = 1;
            bezier = [
              "overshot,0.13,0.99,0.29,1.1"
            ];

            animation = [
              "windows,1,4,overshot,slide"
              "border,1,10,default"
              "fade,1,10,default"
              "workspaces,1,4,overshot,slide"
            ];
          };

          dwindle = {
            pseudotile = 1;
            force_split = 0;
          };

          gestures = {
            workspace_swipe = true;
            workspace_swipe_fingers = 4;
            workspace_swipe_min_speed_to_force = 20;
          };

          windowrulev2 = [
            "pin,class:(pinentry-qt)"
            "stayfocused,class:(pinentry-qt)"
            "noanim,class:(pinentry-qt)"
          ];

          "$mainMod" = "SUPER";

          bindm = [
            "$mainMod,mouse:272,movewindow"
            "$mainMod CTRL,mouse:272,resizewindow"
          ];

          bindl = [
            ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86AudioPlay, exec, playerctl play-pause"
            "$mainMod, XF86AudioPlay, exec, playerctl stop"
            ", XF86AudioPrev, exec, playerctl previous"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86Sleep, exec, swaync-client --toggle-dnd"
          ]
          ++ optionals (config.hardware.brillo.enable) [
            ", XF86MonBrightnessUp, exec, brillo -A 5"
            ", XF86MonBrightnessDown, exec, brillo -U 5"
            "$mainMod, XF86MonBrightnessUp, exec, brillo -k -A 5"
            "$mainMod, XF86MonBrightnessDown, exec, brillo -k -U 5"
          ];

          bindr = [
            "$mainMod,R,exec, pkill fuzzel || fuzzel -I"
          ];

          bind = [
            "$mainMod,RETURN,exec,foot"
            "$mainMod,Q,killactive,"
            # "$mainMod,M,exit,"
            "$mainMod,S,togglefloating,"
            "$mainMod,P,pseudo,"
            "$mainMod,B,togglesplit,"
            "$mainMod,TAB,focuscurrentorlast,"

            # Colemak
            "$mainMod,m,movefocus,l"
            "$mainMod,i,movefocus,r"
            "$mainMod,e,movefocus,u"
            "$mainMod,n,movefocus,d"

            "$mainMod SHIFT,m,movewindow,l"
            "$mainMod SHIFT,i,movewindow,r"
            "$mainMod SHIFT,e,movewindow,u"
            "$mainMod SHIFT,n,movewindow,d"

            "$mainMod CTRL,n,workspace,e+1"
            "$mainMod CTRL,e,workspace,e-1"
            "$mainMod,mouse_down,workspace,e+1"
            "$mainMod,mouse_up,workspace,e-1"

            "$mainMod,g,togglegroup"
            "$mainMod,tab,changegroupactive"

            "$mainMod,grave,submap,qwerty"
          ]
          ++ (
            (
              flr: ceil:
                with builtins;
                concatLists (
                  genList
                    (
                      n:
                      let
                        i = toString (flr + n);
                      in
                      [
                        "$mainMod,${i},workspace,${i}"
                        "$mainMod SHIFT,${i},movetoworkspace,${i}"
                      ]
                    )
                    (ceil - flr + 1)
                )
            )
              1
              9
          );

          submap.qwerty.bind = [
            # QWERTY
            "$mainMod,h,movefocus,l"
            "$mainMod,l,movefocus,r"
            "$mainMod,k,movefocus,u"
            "$mainMod,j,movefocus,d"
            "$mainMod SHIFT,h,movewindow,l"
            "$mainMod SHIFT,l,movewindow,r"
            "$mainMod SHIFT,k,movewindow,u"
            "$mainMod SHIFT,j,movewindow,d"

            "$mainMod,grave,submap,reset"
          ];
        };
      };

      programs.foot.enable = true;
      programs.foot.settings = {
        main.pad = "15x15";
        main.term = "xterm-256color";
        main.font = with config.stylix.fonts; "${monospace.name}:size=${builtins.toString sizes.terminal}";
        mouse.hide-when-typing = "yes";
        cursor.color = "${theme.base00} ${theme.base05}";
      };

      programs.fuzzel = {
        enable = true;
        settings = {
          main.terminal = "${pkgs.foot}/bin/foot";
          main.layer = "overlay";
          main.prompt = "❯   ";
          border.radius = 0;
          border.width = 3;
        };
      };

      programs.wpaperd = {
        enable = true;
        settings.default.path = config.stylix.image;
      };

      systemd.user.services.wpaperd = {
        Unit.PartOf = [ "graphical-session.target" ];
        Unit.After = [ "graphical-session-pre.target" ];

        Service = {
          ExecStart = "${pkgs.wpaperd}/bin/wpaperd";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = {
          WantedBy = [ "hyprland-session.target" ];
        };
      };

      programs.waybar = {
        enable = true;
        systemd.enable = true;
        systemd.target = "hyprland-session.target";
        settings.mainBar =
          let
            swncc = "${pkgs.swaynotificationcenter}/bin/swaync-client";
          in
          {
            layer = "top";
            position = "top";
            height = 35;

            modules-left = [
              "hyprland/workspaces"
            ];

            modules-center =
              optionals isMacBook [ "custom/notch" ]
              ++ optionals (config.home-manager.users.cmacrae.services.playerctld.enable) [ "mpris" ];

            modules-right = [
              "tray"
              # "idle_inhibitor"
              "custom/notifications"
            ]
            ++ optionals isMacBook [ "battery" ]
            ++ optionals (config.hardware.bluetooth.enable) [ "bluetooth" ]
            ++ optionals (config.networking.wireless.enable) [ "network" ]
            ++ optionals (config.services.pipewire.enable) [ "wireplumber" ]
            ++ [ "clock" ];

            "hyprland/workspaces" = {
              sort-by = "number";
              format = "";
            };

            bluetooth = {
              format-on = " ";
              format-connected = " ";
              format-disabled = " ";
              tooltip-format = "{controller_alias}\t{controller_address}";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            };

            network = {
              format-wifi = "{icon}";
              format-icons = [
                "󰢼"
                "󰢽"
                "󰢾"
              ];
              format-disconnected = "󰞃";
              tooltip-format-wifi = ''
                {essid}
                {ipaddr}
              '';
              tooltip-format-disconnected = "Disconnected";
            };

            clock.format = "  {:%H:%M} ";
            clock.on-click = "${swncc} -t -sw";

            battery = {
              format = "{icon}  {capacity}%";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              format-charging-full = "";
              full-at = 100;
              states.full = 100;
              states.warning = 30;
              states.critical = 15;
            };

            # idle_inhibitor.format = ""; # TODO: implement with swayidle

            wireplumber.format = "{icon}  {volume}%";
            wireplumber.format-muted = "󰖁";
            wireplumber.format-icons = [
              ""
              ""
              ""
            ];
            wireplumber.scroll-step = "1.5";

            "custom/notifications" =
              let
                pos = ''
                  <span rise='-2000'>
                '';
                dot = ''
                  <span foreground='#${theme.base08}'><sup></sup></span></span>
                '';
              in
              {
                tooltip = false;
                format = "{icon}";
                format-icons = {
                  notification = "${pos} ${dot} ";
                  none = "";
                  dnd-notification = "${pos} ${dot} ";
                  dnd-none = "";
                  inhibited-notification = "${pos} ${dot} ";
                  inhibited-none = "";
                  dnd-inhibited-notification = "${pos} ${dot} ";
                  dnd-inhibited-none = "";
                };
                return-type = "json";
                exec = "${swncc} -swb";
                on-click = "${swncc} -t -sw";
                on-click-right = "${swncc} -d -sw";
                escape = true;
              };

            "custom/notch" = {
              tooltip = false;
              min-length = 25;
              max-length = 25;
              align = "0.5";
              format = " ";
            };

            mpris = {
              align = 0;
              min-length = 33;
              max-length = 33;
              format =
                "{status_icon}  <span foreground='#${theme.base0D}'>{artist}</span> ࢇ <span foreground='#${theme.base0C}'> {title}</span>";
              dynamic-len = 30;
              player-icons.default = "▶";
              status-icons.playing = "";
              status-icons.paused = "⏸";
            };
          };

        style = cssWithTheme ./waybar.css;
      };

      services.playerctld.enable = true;

      programs.swaync.enable = true;
      programs.swaync.systemd.enable = true;
      programs.swaync.style = cssWithTheme ./swaync.css;

      programs.swaync.settings = {
        notification-icon-size = 44;
        notification-body-image-height = 80;
        notification-body-image-width = 180;
        control-center-width = 370;
        notification-window-width = 370;
        # scripts = {
        #   example-script = {
        #     exec = "echo 'Do something...'";
        #     urgency = "Normal";
        #   };
        #   example-action-script = {
        #     exec = "echo 'Do something actionable!'";
        #     urgency = "Normal";
        #     run-on = "action";
        #   };
        # };
        notification-visibility = {
          spotify = {
            state = "muted";
            urgency = "Low";
            app-name = "Spotify";
          };
        };
        widgets = [
          "inhibitors"
          "dnd"
          "mpris"
          "title"
          "notifications"
        ];
        widget-config = {
          inhibitors.text = "Inhibitors";
          inhibitors.button-text = "clear";
          inhibitors.clear-all-button = true;

          title.text = "Notifications";
          title.clear-all-button = true;
          title.button-text = "clear";

          dnd.text = "DoNotDisturb";

          mpris.image-size = 96;
          mpris.image-radius = 7;
        };
      };

      xdg.enable = true;
      xdg.userDirs.enable = true;
      xdg.userDirs.createDirectories = true;
      xdg.portal = {
        enable = true;
        config.hyprland.default = [
          "gtk"
          "hyprland"
        ];
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-hyprland
        ];
      };

      programs.obs-studio.enable = true;

      # Storage Management
      services.udiskie.enable = true;
      services.udiskie.notify = false;
      services.udiskie.tray = "never";
    };
}
