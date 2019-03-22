{ config, pkgs, ... }:

{
  nix.trustedUsers = [ "root" "@wheel" ];

  time.timeZone = "Europe/London";

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ vim nfs-utils ];
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts
      dina-font
      proggyfonts
      emacs-all-the-icons-fonts
    ];
   };

  services.illum.enable = true;

  services.openssh.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  security.sudo.enable = true;
}

