{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.spacebar;

  spacebar = pkgs.callPackage ../pkgs/spacebar {
    inherit (pkgs.darwin.apple_sdk.frameworks)
      Carbon Cocoa ScriptingBridge;
  };

  toSpacebarConfig = opts:
    concatStringsSep "\n" (
      mapAttrsToList
        (o: v: "spacebar -m config ${o} "
               + (if strings.hasSuffix "_font" o
                  then ''"${v}"''
                  else "${v}")
        )
        opts
    );
in

{
  options.services.spacebar = with types; {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable the spacebar service.";
    };

    package = mkOption {
      type = path;
      default = spacebar;
      description = "This option specifies the spacebar package to use.";
    };

    config = {
      text_font = mkOption {
        type = str;
        default = "Helvetica Neue:Bold:12.0";
        description = ''
          Name, style and size of font to use for drawing text.
          Follow this format: <literal><font_family>:<font_style>:<font_size></literal>
          Use Font Book.app to identify the correct name.
        '';
      };

      icon_font = mkOption {
        type = str;
        default = "FontAwesome:Regular:12.0";
        description = ''
          Name, style and size of font to use for drawing icon symbols.
          Follow this format: <literal><font_family>:<font_style>:<font_size></literal>
          Use Font Book.app to identify the correct name.
        '';
      };

      background_color = mkOption {
        type = str;
        default = "0xff202020";
        description = ''
          Color to use for drawing status bar background.
          Format should be a masked hexadecimal.
        '';
      };

      foreground_color = mkOption {
        type = str;
        default = "0xffa8a8a8";
        description = ''
          Color to use for drawing status bar foreground.
          Format should be a masked hexadecimal.
        '';
      };

      space_icon_strip = mkOption {
        type = str;
        default = "I II III IV V VI VII VIII IX X";
        description = ''
          Symbols separated by whitespace to be used for visualizing spaces.
        '';
      };

      power_icon_strip = mkOption {
        type = str;
        default = " ";
        description = ''
          Two symbols separated by whitespace.
          The first symbol represents battery power and the second symbol indicates AC.
        '';
      };

      space_icon = mkOption {
        type = str;
        default = "";
        description = ''
          General symbol to use for any given space that does not have a match in space_icon_strip.
        '';
      };

      clock_icon = mkOption {
        type = str;
        default = "";
        description = ''
          Symbol to represent the current time.
        '';
      };

      clock_format = mkOption {
        type = str;
        default = "%d/%m/%y %R";
        description = ''
          Date format to display the current time.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      security.accessibilityPrograms = [ "${cfg.package}/bin/spacebar" ];

      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.spacebar = {
        serviceConfig.ProgramArguments = [ "${cfg.package}/bin/spacebar" "-V" "--config" "/etc/spacebarrc" ];
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
        serviceConfig.EnvironmentVariables = {
          PATH = "${cfg.package}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };

      environment.etc."spacebarrc".source = pkgs.writeScript "etc-spacebarrc" ''
        ${toSpacebarConfig cfg.config}
        echo "spacebar config loaded"
      '';
    })
  ];
}
