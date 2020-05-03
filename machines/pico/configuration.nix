{ lib, config, pkgs, ...}:
{
  imports = lib.attrValues (import ../../modules);
  local.darwin.machine = "pico";
}
