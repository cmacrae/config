{ config, lib, pkgs, ... }:


let
  inherit (lib) mkOption types;
  cfg = config.programs.aerospace;
in
{
  options.programs.aerospace = {
    enable = lib.mkEnableOption "Aerospace";

    package = mkOption {
      type = types.package;
      default = pkgs.aerospace;
      description = "The Aerospace package to use.";
    };

    config = mkOption {
      type = types.attrs;
      default = { };
      description = "Attribute set that will be converted to TOML for Aerospace configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."aerospace/aerospace.toml".source =
      pkgs.writers.writeTOML "aerospace.toml" cfg.config;

    xdg.configFile."aerospace/aerospace.toml".onChange =
      "${cfg.package}/bin/aerospace reload-config";

    launchd.agents.aerospace = {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/Applications/Aerospace.app/Contents/MacOS/Aerospace"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          PATH = "${cfg.package}/bin:${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/aerospace.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/aerospace.error.log";
      };
    };

  };
}
