{ inputs, ... }:
{
  imports = [ 
    "${inputs.self}/modules/shared"
   ];

  i18n.defaultLocale = "en_GB.UTF-8";
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  networking.domain = "cmacr.ae";
}
