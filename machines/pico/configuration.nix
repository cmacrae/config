{ lib, config, pkgs, ...}:
{
  imports = lib.attrValues (import ../../modules);
  macintosh.machine = "pico";
}
