{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.yabai;

  toYabaiConfig = opts:
    concatStringsSep "\n" (mapAttrsToList
      (p: v: "yabai -m config ${p} ${toString v}") opts);

in

{
  options.services.yabai = with types; {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable the yabai window manager.";
    };

    package = mkOption {
      type = path;
      default = pkgs.yabai;
      description = "The yabai package to use.";
    };

    configPath = mkOption {
      type = path;
      default = "/etc/yabairc";
      description = "Path to the executable <filename>yabairc</filename> file.";
    };

    enableScriptingAddition = mkOption {
      type = bool;
      default = false;
      description = ''
        Whether to enable yabai's scripting-addition.
        SIP must be disabled for this to work.
      '';
    };

    config = mkOption {
      type = attrs;
      default = {};
      description = ''
        Key/Value pairs to pass to yabai's 'config' domain, via the configuration file.
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
      security.accessibilityPrograms = [ "${cfg.package}/bin/yabai" ];

      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.yabai = {
        serviceConfig.ProgramArguments = [ "${cfg.package}/bin/yabai" ]
                                         ++ optionals (cfg.configPath != "") [ "-c" cfg.configPath ];
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
        serviceConfig.EnvironmentVariables = {
          PATH = "${cfg.package}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        serviceConfig.StandardOutPath = "/tmp/yabai.out.log";
        serviceConfig.StandardErrorPath = "/tmp/yabai.err.log";
      };
    })

    (mkIf (cfg.configPath == "/etc/yabairc") {
      environment.etc."yabairc".source = pkgs.writeScript "etc-yabairc" (''
        ${toYabaiConfig cfg.config}
      '' + optionalString (cfg.extraConfig != "") cfg.extraConfig);
    })

    # TODO: [Darwin] Handle removal of yabai scripting additions
    (mkIf (cfg.enableScriptingAddition) {
      launchd.daemons.yabai-sa = {
        script = ''
          if [ ! $(${cfg.package}/bin/yabai --check-sa) ]; then
            ${cfg.package}/bin/yabai --install-sa
          fi
        '';

        serviceConfig.RunAtLoad = true;
        serviceConfig.KeepAlive.SuccessfulExit = false;
      };
    })
  ];
}
