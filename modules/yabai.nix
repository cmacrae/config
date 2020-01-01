{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.yabai;

  # TODO: [Darwin] Handle removal of yabai scripting additions
  yabai = pkgs.callPackage ../pkgs/yabai.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks)
      Carbon Cocoa ScriptingBridge;
  };

in

{
  options = {
    services.yabai.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the yabai window manager.";
    };

    services.yabai.package = mkOption {
      type = types.path;
      default = yabai;
      description = "This option specifies the yabai package to use.";
    };

    services.yabai.configPath = mkOption {
      type = types.path;
      default = "";
      example = "~/.yabairc";
      description = "Path to the executable <filename>yabairc</filename> file.";
    };

    services.yabai.enableScriptingAddition = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable yabai's scripting-addition.";
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
        serviceConfig.ProcessType = "Interactive";

        # TODO: [Darwin](yabai) Once done with debugging, disable logging
        #       Same for all of these entries
        serviceConfig.StandardOutPath = "/tmp/yabai.log";
        serviceConfig.StandardErrorPath = "/tmp/yabai-error.log";
      };
    })

    (mkIf (cfg.enableScriptingAddition) {
      launchd.daemons.yabai-sa = {
        script = ''
          if [ ! $(${cfg.package}/bin/yabai --check-sa) ]; then
            ${cfg.package}/bin/yabai --install-sa
          fi
        '';

        serviceConfig.RunAtLoad = true;
        serviceConfig.KeepAlive.SuccessfulExit = false;

        serviceConfig.StandardOutPath = "/tmp/yabai-sa.log";
        serviceConfig.StandardErrorPath = "/tmp/yabai-sa-error.log";
      };
    })
  ];
}
