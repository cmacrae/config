{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) optional;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

in
{
  # imports = [ inputs.lollypops.nixosModules.lollypops ];

  # lollypops.secrets.default-cmd = "pass";
  # lollypops.secrets.cmd-name-prefix = "Tech/nix-secrets/";

  system.configurationRevision = inputs.self.rev or null;

  home-manager.backupFileExtension = "hm-backup";

  nixpkgs.config.allowUnfree = true;

  nix = {
    optimise.automatic = true;
    settings = {
      trusted-users = (optional isLinux "@wheel") ++ (optional isDarwin "@admin");
      warn-dirty = false;
      experimental-features = "nix-command flakes";

      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];
  environment.systemPackages = with pkgs; [
    curl
    file
    git
    rsync
    vim
    zsh
  ];

  time.timeZone = "Europe/London";
}
