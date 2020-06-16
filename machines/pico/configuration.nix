{ lib, config, pkgs, ...}:
{
  imports = lib.attrValues (import ../../modules);
  networking.hostName = "pico";
}
