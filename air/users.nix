{configuration, pkgs, ...}:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;
in
{
  imports = [ "${home-manager}/nixos" ];

  users.users.cmacrae = {
    description = "Calum MacRae";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "sway" "networkmanager" ];
    shell = pkgs.zsh;
  };

  home-manager.users.cmacrae = {
    home.packages = with pkgs; [
      firefox
      fzf
      git
      gnupg
      jq
      mpv
      pass
      ripgrep
      vim
      youtube-dl
    ];

    programs.browserpass.enable = true;

    programs.git = {
      enable = true;
      userName = "cmacrae";
      userEmail = "calum0macrae@gmail.com";
    };
  };
}
