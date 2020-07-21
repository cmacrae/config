{ lib, config, pkgs, ...}:

{
  imports = lib.attrValues (import ../../modules);

  networking.hostName = "workbook";
  home-manager.users.cmacrae.programs.git.userName = "Calum MacRae";
  home-manager.users.cmacrae.programs.git.userEmail = "calum.macrae@moo.com";
  home-manager.users.cmacrae.programs.git.signing.signByDefault = false;
  environment.etc."resolver/pantheon.cmacr.ae".text = "nameserver 10.0.0.2";
  services.spacebar.config.space_icon_strip = "    ";
}
