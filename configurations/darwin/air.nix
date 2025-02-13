{ ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "air";

  home-manager.users.cmacrae = {
    programs.aerospace.enable = false;
    programs.jankyborders.enable = false;
  };
}
