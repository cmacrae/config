{ config, pkgs, lib, inputs, ... }:
{
  imports = [ inputs.lollypops.nixosModules.lollypops ];
  lollypops.secrets.default-cmd = "pass";
  lollypops.secrets.cmd-name-prefix = "Tech/nix-secrets/";

  system.configurationRevision = inputs.self.rev or null;

  # TODO: use predicate
  nixpkgs.config.allowUnfree = true;
  nix = {
    registry = builtins.mapAttrs (_: v: { flake = v; }) inputs;
    nixPath =
      lib.mapAttrsToList (k: v: "${k}=${v.to.path}") config.nix.registry;
    settings = rec {
      allowed-users = [ "@wheel" ];
      auto-optimise-store = true;
      warn-dirty = false;
      experimental-features = "nix-command flakes";

      substituters = [
        "https://cache.nixos.org"
        "https://cachix.org/api/v1/cache/cmacrae"
        "https://cachix.org/api/v1/cache/nix-community"
      ];
      trusted-substituters = substituters;
      trusted-public-keys = [
        "cmacrae.cachix.org-1:5Mp1lhT/6baI3eAqnEvruhLrrXE9CKe27SbnXqjwXfg="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];
  environment.systemPackages = with pkgs; [ curl file git rsync vim zsh ];

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  networking.domain = "cmacr.ae";

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
