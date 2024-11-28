{ config, lib, pkgs, ... }:


let
  inherit (lib) mkOption types;
  cfg = config.programs.jankyborders;
in
{
  options.programs.jankyborders = {
    enable = lib.mkEnableOption "Janky Borders";

    package = mkOption {
      type = types.package;
      default = pkgs.jankyborders;
      description = "The Janky Borders package to use.";
    };

    config = mkOption {
      type = types.attrs;
      default = { };
      description =
        "Attribute set that will be converted to arguments for Janky Borders configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    launchd.agents.jankyborders = {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/bin/borders"
        ] ++ builtins.attrValues
          (builtins.mapAttrs
            (k: v: "${k}=${builtins.toString v}")
            cfg.config);
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          PATH = "${cfg.package}/bin:${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/jankyborders.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/jankyborders.error.log";
      };
    };

  };
}
