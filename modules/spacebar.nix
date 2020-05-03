{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.spacebar;

  toSpacebarConfig = opts:
    concatStringsSep "\n" (mapAttrsToList
      (p: v: "spacebar -m config ${p} ${toString v}") opts);
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
      default = pkgs.spacebar;
      description = "This option specifies the spacebar package to use.";
    };

    configPath = mkOption {
      type = path;
      default = "/etc/spacebarrc";
      description = "Path to the executable <filename>spacebarrc</filename> file.";
    };

    config = mkOption {
      type = attrs;
      default = {};
      description = ''
        Key/Value pairs to pass to spacebar's 'config' domain, via the configuration file.
      '';
    };

    extraConfig = mkOption {
      type = str;
      default = "";
      description = "Extra arbitrary configuration to append to the configuration file";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      security.accessibilityPrograms = [ "${cfg.package}/bin/spacebar" ];

      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.spacebar = {
        serviceConfig.ProgramArguments = [ "${cfg.package}/bin/spacebar" ]
                                         ++ optionals (cfg.configPath != "") [ "-c" cfg.configPath ];
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
        serviceConfig.EnvironmentVariables = {
          PATH = "${cfg.package}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    })

    (mkIf (cfg.configPath == "/etc/spacebarrc") {
      environment.etc."spacebarrc".source = pkgs.writeScript "etc-spacebarrc" (''
        ${toSpacebarConfig cfg.config}
      '' + optionalString (cfg.extraConfig != "") cfg.extraConfig);
    })
  ];
}
