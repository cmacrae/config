{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "nilbook";

  homebrew.casks = [ "loom" "slack" "zoom" ];

  home-manager.users.cmacrae = {
    home.packages = with pkgs; [
      awscli2
      terraform-ls
    ];
  };
}
