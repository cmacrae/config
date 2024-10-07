{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.programs.emacs-config;
in
{
  options.programs.emacs-config = {
    enable = lib.mkEnableOption "Emacs configuration";

    package = mkOption {
      type = types.package;
      # FIXME: get overlays working
      default = inputs.self.packages.${pkgs.stdenv.system}.emacs-env;
      defaultText = lib.literalExpression "pkgs.emacs-env";
      description = "The default Emacs derivation to use.";
    };

    configPackage = mkOption {
      type = types.package;
      # FIXME: get overlays working
      default = inputs.self.packages.${pkgs.stdenv.system}.emacs-config;
      defaultText = lib.literalExpression "pkgs.emacs-config";
      description = "The default Emacs config derivation to use.";
    };

    enableUserDirectory = mkOption {
      default = true;
      type = types.bool;
      description = "Whether to enable user Emacs directory files.";
    };

    defaultEditor = mkOption {
      default = true;
      type = types.bool;
      description = "Whether to use Emacs as default editor.";
    };
  };

  config = mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ cfg.package ] ++ lib.optionals cfg.enableUserDirectory cfg.configPackage.buildInputs;
    }
    (mkIf cfg.enableUserDirectory {
      xdg.configFile.emacs = {
        source = cfg.configPackage;
        recursive = true;
      };
    })
    (mkIf cfg.defaultEditor { home.sessionVariables.EDITOR = "emacsclient"; })
  ]);
}
