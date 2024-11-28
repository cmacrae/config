{ pkgs, inputs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "nilbook";

  system.activationScripts.extraActivation.text = ''
    if [ ! -d "/Library/Apple/usr/share/rosetta" ]; then
      echo "Installing Rosetta..."
      softwareupdate --install-rosetta --agree-to-license
    fi
  '';

  homebrew.casks = [ "loom" "slack" "zoom" ];

  home-manager.users.cmacrae = {
    imports = [
      inputs.limani.homeModules.default
      inputs.limani.homeModules.podman
    ];

    home.packages = with pkgs; [
      awscli2
      ssm-session-manager-plugin
      terraform-ls
      nodePackages.bash-language-server
    ];

    programs.limani.enable = true;
    programs.limani.podman.enable = true;
    programs.limani.podman.rosetta.enable = true;
    programs.limani.podman.args = [
      "--cpus 8"
      "--memory 8"
    ];
  };
}
