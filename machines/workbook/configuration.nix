{ lib, config, pkgs, ...}:
{
  imports = lib.attrValues (import ../../modules);

  local.home.git = {
    userName = "Calum MacRae";
    userEmail = "calum.macrae@moo.com";
  };

  local.darwin.machine = "workbook";
}
