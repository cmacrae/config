{ config, pkgs, lib, inputs, ... }:
let
  inherit (lib) mkForce optional;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

in
{
  # imports = [ inputs.lollypops.nixosModules.lollypops ];

  # lollypops.secrets.default-cmd = "pass";
  # lollypops.secrets.cmd-name-prefix = "Tech/nix-secrets/";

  system.configurationRevision = inputs.self.rev or null;

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      trusted-users =
        (optional isLinux "@wheel")
        ++
        (optional isDarwin "@admin");
      auto-optimise-store = true;
      warn-dirty = false;
      experimental-features = "nix-command flakes";

      substituters = [
        "https://cache.nixos.org"
        "https://cmacrae.cachix.org"
        "https://nix-community.cachix.org"
      ];
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
}
