{ lib, config, pkgs, ...}:
{
  imports = lib.attrValues (import ../../modules);

  macintosh.machine = "workbook";
  home-manager.users.cmacrae.programs.git.userName = "Calum MacRae";
  home-manager.users.cmacrae.programs.git.userEmail = "calum.macrae@moo.com";
}
