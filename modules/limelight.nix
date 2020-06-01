{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.limelight;

  toLimelightConfig = opts:
    concatStringsSep "\n" (mapAttrsToList
      (p: v: "limelight -m config ${p} ${toString v}") opts);

  configFile = mkIf (cfg.config != {} || cfg.extraConfig != "")
    "${pkgs.writeScript "limelightrc" (
      (if (cfg.config != {})
       then "${toLimelightConfig cfg.config}"
       else "")
      + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig + "\n"))}";
in

{
  options = with types; {
    services.limelight.enable = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable the limelight service.";
    };

    services.limelight.package = mkOption {
      type = path;
      description = "The limelight package to use.";
    };

    services.limelight.config = mkOption {
      type = attrs;
      default = {};
      example = literalExample ''
        {
          limelight -m config width        = 4;
          limelight -m config radius       = 0;
          limelight -m config placement    = "interior";
          limelight -m config active_color = "0xff775759";
          limelight -m config normal_color = "0xff555555";
        }
      '';
      description = ''
        Key/Value pairs to pass to limelight's 'config' domain, via the configuration file.
      '';
    };

    services.limelight.extraConfig = mkOption {
      type = str;
      default = "";
      example = literalExample ''
        echo "limelight configuration loaded.."
      '';
      description = "Extra arbitrary configuration to append to the configuration file";
    };
  };

  config = mkIf (cfg.enable) {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.limelight = {
      serviceConfig.ProgramArguments = [ "${cfg.package}/bin/limelight" ]
                                       ++ optionals (cfg.config != {} || cfg.extraConfig != "") [ "-c" configFile ];

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
      serviceConfig.EnvironmentVariables = {
        PATH = "${cfg.package}/bin:${config.environment.systemPath}";
      };
    };
  };
}
