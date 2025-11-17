{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    isStorePath
    literalExpression
    types
    ;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;

  jsonFormat = pkgs.formats.json { };
  cfg = config.programs.swaync;

in
{
  # meta.maintainers = with lib.maintainers; [ cmacrae ];

  options.programs.swaync = with types; {
    enable = mkEnableOption "SwayNotificationCenter";

    package = mkOption {
      type = package;
      default = pkgs.swaynotificationcenter;
      defaultText = literalExpression "pkgs.swaynotificationcenter";
      description = ''
        SwayNotificationCenter package to use. Set to `null` to use the default package.
      '';
    };

    settings = mkOption {
      type = attrs;
      default = { };
      description = ''
        Configuration for SwayNotificationCenter, see <https://github.com/ErikReider/SwayNotificationCenter>
        for supported values.
      '';
      example = literalExpression ''
        {
          mainBar = {
            layer = "top";
            position = "top";
            height = 30;
            output = [
              "eDP-1"
              "HDMI-A-1"
            ];
            modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
            modules-center = [ "sway/window" "custom/hello-from-waybar" ];
            modules-right = [ "mpd" "custom/mymodule#with-css-id" "temperature" ];

            "sway/workspaces" = {
              disable-scroll = true;
              all-outputs = true;
            };
            "custom/hello-from-waybar" = {
              format = "hello {}";
              max-length = 40;
              interval = "once";
              exec = pkgs.writeShellScript "hello-from-waybar" '''
                echo "from within waybar"
              ''';
            };
          };
        }
      '';
    };

    systemd.enable = mkEnableOption "SwayNotificationCenter systemd integration";

    systemd.target = mkOption {
      type = str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the SwayNotificationCenter service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };

    style = mkOption {
      type = nullOr (either path lines);
      default = null;
      description = ''
        CSS style of the notification center.

        See <https://github.com/ErikReider/SwayNotificationCenter>
        for the documentation.

        If the value is set to a path literal, then the path will be used as the css file.
      '';
      example = ''
        * {
          border: none;
          border-radius: 0;
          font-family: Source Code Pro;
        }
        window#waybar {
          background: #16191C;
          color: #AAB2BF;
        }
        #workspaces button {
          padding: 0 5px;
        }
      '';
    };
  };

  config =
    let
      configSource = jsonFormat.generate "swaync-config.json" (
        {
          "$schema" = "${cfg.package}/etc/xdg/swaync/configSchema.json";
        }
        // cfg.settings
      );

    in
    mkIf cfg.enable (mkMerge [
      {
        assertions = [
          (lib.hm.assertions.assertPlatform "programs.swaync" pkgs lib.platforms.linux)
        ];

        home.packages = [ cfg.package ];

        xdg.configFile."swaync/config.json" = mkIf (cfg.settings != { }) {
          source = configSource;
          onChange = ''
            ${cfg.package}/bin/swaync-client -R
          '';
        };

        xdg.configFile."swaync/style.css" = mkIf (cfg.style != null) {
          source =
            if builtins.isPath cfg.style || isStorePath cfg.style then
              cfg.style
            else
              pkgs.writeText "swaync/style.css" cfg.style;
          onChange = ''
            ${cfg.package}/bin/swaync-client -rs
          '';
        };
      }

      (mkIf cfg.systemd.enable {
        systemd.user.services.swaync = {
          Unit = {
            Description = "A simple GTK based notification daemon for Wayland compositors.";
            Documentation = "https://github.com/ErikReider/SwayNotificationCenter";
            ConditionEnvironment = "WAYLAND_DISPLAY";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session-pre.target" ];
          };

          Service = {
            ExecStart = "${cfg.package}/bin/swaync";
            ExecReload = "${cfg.package}/bin/swaync-client -R ; ${cfg.package}/bin/swaync-client -rs";
            Restart = "on-failure";
            KillMode = "mixed";
          };

          Install = {
            WantedBy = [ cfg.systemd.target ];
          };
        };
      })
    ]);
}
