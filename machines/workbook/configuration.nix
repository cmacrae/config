{ lib, config, pkgs, ...}:

{
  imports = lib.attrValues (import ../../modules);

  networking.hostName = "workbook";
  home-manager.users.cmacrae.programs.git.userName = "Calum MacRae";
  services.spacebar.config.space_icon_strip = "    ";
}
