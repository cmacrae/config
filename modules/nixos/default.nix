{ inputs, pkgs, ... }:
{
  imports = [
    "${inputs.self}/modules/shared"
    inputs.home-manager.nixosModules.home-manager
  ];

  i18n.defaultLocale = "en_GB.UTF-8";
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  networking.domain = "cmacr.ae";

  users.users.cmacrae = {
    description = "Calum MacRae";
    shell = pkgs.zsh;
    home = "/home/cmacrae";
    isNormalUser = true;
    extraGroups = [
      "input"
      "tty"
      "video"
      "wheel"
    ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.cmacrae = {
      imports = [
        inputs.self.homeModules.default
      ];
    };
  };
}
