{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  # Audio
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Compat
  security.polkit.enable = true;
  fonts.enableDefaultPackages = true;
  programs.dconf.enable = true;

  # Bluetooth
  # services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  # Screen
  hardware.brillo.enable = true;

  # Yubikey
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Compositor
  programs.hyprland.enable = true;
  programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.hyprland;

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
  qt.platformTheme = "gtk2";

  # Storage Management
  services.udisks2.enable = true;

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
      rose-pine = with config.lib.stylix.colors; {
        base = base00;
        overlay = base02;
        muted = base04;
        text = base05;
        love = base09;
        gold = base0A;
        rose = base0B;
        pine = base0C;
        foam = base0D;
        iris = base0E;
      };

      cssWithRosePine = file: pkgs.lib.concatStringsSep "\n"
        (
          pkgs.lib.mapAttrsToList
            (name: value:
              "@define-color ${name} #${value};"
            )
            rose-pine) + builtins.readFile file;

    in
    {

      imports = [
        inputs.self.homeModules.swaync
        inputs.hyprland.homeManagerModules.default
      ];

      stylix.targets.gtk.enable = false;
      stylix.targets.foot.enable = false;
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

        Install = { WantedBy = [ "hyprland-session.target" ]; };
      };

      home.packages = with pkgs; [
        chatterino2
        # discord TODO: no pkg for aarch64?
        gnome.gnome-disk-utility
        libnotify
        pantheon.elementary-calculator
        pinentry
        playerctl
        qpwgraph
        # spotify TODO: no pkg for aarch64?
        # streamlink TODO: no pkg for aarch64?
        # streamlink-twitch-gui-bin TODO: no pkg for aarch64?
        wayland-utils
        wev
        # wineWowPackages.waylandFull
        # wineasio TODO: no pkg for aarch64?
        # winetricks TODO: no pkg for aarch64?
        wireplumber
        wl-clipboard
        xdg-utils
        xfce.thunar
        yubioath-flutter
      ];

      gtk = {
        enable = true;
        theme = {
          package = pkgs.rose-pine-gtk-theme;
          name = "rose-pine";
        };

        iconTheme = {
          package = pkgs.rose-pine-icon-theme;
          name = "rose-pine";
        };
      };

      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        settings = {
          monitor = "eDP-1,highres,auto,1.600000";

          input = {
            follow_mouse = 1;
            kb_options = "ctrl:nocaps";
            sensitivity = "0.65";
            touchpad.natural_scroll = true;
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          general = {
            apply_sens_to_raw = 0;
            gaps_in = 5;
            gaps_out = 12;
            border_size = 3;
            "col.active_border" = "0xff${rose-pine.iris}";
            "col.inactive_border" = "0xff${rose-pine.muted}";
            cursor_inactive_timeout = 3;
          };

          decoration = {
            rounding = 0;
            drop_shadow = true;
            shadow_range = 100;
            shadow_render_power = 5;
            "col.shadow" = "0x33000000";
            "col.shadow_inactive" = "0x22000000";
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
            ", XF86MonBrightnessUp, exec, brillo -A 5"
            ", XF86MonBrightnessDown, exec, brillo -U 5"
            ", XF86AudioPlay, exec, playerctl play-pause"
            "$mainMod, XF86AudioPlay, exec, playerctl stop"
            ", XF86AudioPrev, exec, playerctl previous"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86Sleep, exec, swaync-client --toggle-dnd"
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


            # NOTE: colemak
            # "$mainMod,m,movefocus,l"
            # "$mainMod,i,movefocus,r"
            # "$mainMod,e,movefocus,u"
            # "$mainMod,n,movefocus,d"

            "$mainMod,h,movefocus,l"
            "$mainMod,l,movefocus,r"
            "$mainMod,k,movefocus,u"
            "$mainMod,j,movefocus,d"

            # NOTE: colemak
            # "$mainMod SHIFT,m,movewindow,l"
            # "$mainMod SHIFT,i,movewindow,r"
            # "$mainMod SHIFT,e,movewindow,u"
            # "$mainMod SHIFT,n,movewindow,d"

            "$mainMod SHIFT,h,movewindow,l"
            "$mainMod SHIFT,l,movewindow,r"
            "$mainMod SHIFT,k,movewindow,u"
            "$mainMod SHIFT,j,movewindow,d"

            "$mainMod CTRL,n,workspace,e+1"
            "$mainMod CTRL,e,workspace,e-1"
            "$mainMod,mouse_down,workspace,e+1"
            "$mainMod,mouse_up,workspace,e-1"

            "$mainMod,g,togglegroup"
            "$mainMod,tab,changegroupactive"
          ] ++ (
            (flr: ceil:
              with builtins;
              concatLists (genList
                (n:
                  let i = toString (flr + n); in [
                    "$mainMod,${i},workspace,${i}"
                    "$mainMod SHIFT,${i},movetoworkspace,${i}"
                  ]
                )
                (ceil - flr + 1))) 1 9
          );
        };
      };

      programs.foot.enable = true;
      programs.foot.settings = with rose-pine; {
        main.pad = "15x15";
        main.term = "xterm-256color";
        main.font =
          with config.stylix.fonts;
          "${monospace.name}:size=${builtins.toString sizes.terminal}";
        mouse.hide-when-typing = "yes";
        cursor.color = "${base} ${text}";
        colors = {
          background = base;
          foreground = text;
          regular0 = overlay;
          regular1 = love;
          regular2 = pine;
          regular3 = gold;
          regular4 = foam;
          regular5 = iris;
          regular6 = rose;
          regular7 = text;
          bright0 = muted;
          bright1 = love;
          bright2 = pine;
          bright3 = gold;
          bright4 = foam;
          bright5 = iris;
          bright6 = rose;
          bright7 = text;
        };
      };

      programs.firefox.enable = true;
      # programs.firefox.policies = {
      #   Extensions.Install =
      #     with config.home-manager.users.cmacrae.programs.firefox.package
      #     [
      #       "https://releases.mozilla.org/pub/firefox/releases/${version}/PLATFORM/xpi/LANGUAGE.xpi"
      #   ];
      # };
      programs.firefox.profiles.home = {
        id = 0;
        userChrome = builtins.readFile ../../conf.d/userChrome.css;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          browserpass
          betterttv
          metamask
          reddit-enhancement-suite
          ublock-origin
          vimium
        ];

        search.default = "DuckDuckGo";
        search.force = true;

        settings = {
          "app.update.auto" = false;
          "app.normandy.enabled" = false;
          "beacon.enabled" = false;
          "browser.startup.homepage" = "https://lobste.rs";
          "browser.search.region" = "GB";
          "browser.search.countryCode" = "GB";
          "browser.search.hiddenOneOffs" = "Google,Amazon.com,Bing";
          "browser.search.isUS" = false;
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "browser.newtabpage.enabled" = false;
          "browser.bookmarks.showMobileBookmarks" = true;
          "browser.uidensity" = 1;
          "browser.urlbar.update" = true;
          "datareporting.healthreport.service.enabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "distribution.searchplugins.defaultLocale" = "en-GB";
          "extensions.getAddons.cache.enabled" = false;
          "extensions.getAddons.showPane" = false;
          "extensions.pocket.enabled" = false;
          "extensions.webservice.discoverURL" = "";
          "general.useragent.locale" = "en-GB";
          "identity.fxaccounts.account.device.name" = config.networking.hostName;
          "intl.accept_languages" = "en-GB, en";
          "intl.locale.requested" = "en-GB,en-US";
          "privacy.donottrackheader.enabled" = true;
          "privacy.donottrackheader.value" = 1;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
          "reader.color_scheme" = "auto";
          "services.sync.declinedEngines" = "addons,passwords,prefs";
          "services.sync.engine.addons" = false;
          "services.sync.engineStatusChanged.addons" = true;
          "services.sync.engine.passwords" = false;
          "services.sync.engine.prefs" = false;
          "services.sync.engineStatusChanged.prefs" = true;
          "signon.rememberSignons" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.rejected" = true;
          "toolkit.telemetry.updatePing.enabled" = false;
        };
      };

      programs.fuzzel = {
        enable = true;
        settings = {
          main.terminal = "${pkgs.foot}/bin/foot";
          main.layer = "overlay";
          main.prompt = "❯   ";
          border.radius = 0;
          border.width = 3;
          # colors = with rose-pine; {
          #   text = "${text}ff";
          #   match = "${rose}ff";
          #   border = "${iris}ff";
          #   selection = "${muted}ff";
          #   background = "${base}ff";
          #   selection-text = "${text}ff";
          #   selection-match = "${rose}ff";
          # };
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
          ExecStart = "${pkgs.wpaperd}/bin/wpaperd -n";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "hyprland-session.target" ]; };
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

            modules-center = [
              "cava"
              "custom/notch"
              "mpris"
            ];

            modules-right = [
              "tray"
              # "idle_inhibitor"
              "custom/notifications"
              "bluetooth"
              "network"
              "wireplumber"
              "battery"
              "clock"
            ];

            "hyprland/workspaces" = {
              sort-by = "number";
              format = "";
            };

            bluetooth = {
              format-on = "󰂯 ";
              format-connected = "󰂯 ";
              format-disabled = "󰂲 ";
              tooltip-format = "{controller_alias}\t{controller_address}";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            };

            network = {
              format-wifi = "{icon}";
              format-icons = [ "󰢼" "󰢽" "󰢾" ];
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
              format-icons = [ "" "" "" "" "" ];
              format-charging-full = "";
              full-at = 100;
              states.full = 100;
              states.warning = 30;
              states.critical = 15;
            };

            # idle_inhibitor.format = ""; # TODO: implement with swayidle

            wireplumber.format = "{icon}  {volume}%";
            wireplumber.format-muted = "󰖁";
            wireplumber.format-icons = [ "" "" "" ];
            wireplumber.scroll-step = "1.5";

            "custom/notifications" =
              let
                pos = ''
                  <span rise='-2000'>
                '';
                dot = ''
                  <span foreground='#${rose-pine.love}'><sup></sup></span></span>
                '';
              in
              {
                tooltip = false;
                format = "{icon}";
                format-icons = {
                  notification = "${pos} ${dot} ";
                  none = "";
                  dnd-notification = "${pos} ${dot} ";
                  dnd-none = "";
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

            cava = {
              align = 1;
              min-length = 35;
              max-length = 35;
              tooltip = false;

              framerate = 30;
              autosens = 1;
              bars = 15;
              lower_cutoff_freq = 80;
              higher_cutoff_freq = 8000;
              # hide_on_silence = true;
              method = "pulse";
              source = "auto";
              stereo = true;
              reverse = false;
              bar_delimiter = 0;
              monstercat = false;
              waves = false;
              noise_reduction = 0;
              input_delay = 2;
              format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
              actions.on-click = "mode";
              # cava_config = "${config.users.users.cmacrae.home}/.config/cava/config";
              cava_config = "$XDG_CONFIG_HOME/cava/config";
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
                with rose-pine;
                "{status_icon}  <span foreground='#${iris}'>{artist}</span> ࢇ <span foreground='#${foam}'> {title}</span>";
              dynamic-len = 30;
              player-icons.default = "▶";
              player-icons.firefox = "";
              status-icons.playing = "";
              status-icons.paused = "⏸";
            };
          };

        style = cssWithRosePine ../../conf.d/waybar.css;
      };

      services.playerctld.enable = true;
      programs.cava.enable = true;

      programs.swaync.enable = true;
      programs.swaync.systemd.enable = true;
      programs.swaync.style = cssWithRosePine ../../conf.d/swaync.css;

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
        widgets = [ "inhibitors" "dnd" "mpris" "title" "notifications" ];
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

      programs.obs-studio.enable = true;

      # Storage Management
      services.udiskie.enable = true;
      services.udiskie.notify = false;
      services.udiskie.tray = "never";
    };
}
