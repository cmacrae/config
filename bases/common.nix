{ config, pkgs, ... }: {
  system.stateVersion =
    if pkgs.stdenv.isDarwin then
      4
    else
      config.system.nixos.release;

  nix.settings.cores = 0;
  nix.settings.max-jobs = "auto";
  nix.settings.trusted-users = [ "root" "cmacrae" "admin" ];
  nix.settings.auto-optimise-store = true;

  nix.package = pkgs.nixFlakes;
  # Free up to 1GiB whenever there is less than 100MiB left.
  nix.extraOptions = ''
    experimental-features = nix-command flakes

    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  nixpkgs.config.allowUnfree = true;

  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://cachix.org/api/v1/cache/cmacrae"
    "https://cachix.org/api/v1/cache/nix-community"
  ];

  nix.settings.trusted-substituters = [
    "https://cache.nixos.org"
  ];

  nix.settings.trusted-public-keys = [
    "cmacrae.cachix.org-1:5Mp1lhT/6baI3eAqnEvruhLrrXE9CKe27SbnXqjwXfg="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  time.timeZone = "Europe/London";
  environment.systemPackages = with pkgs; [ file git rsync vim zsh ];
}
