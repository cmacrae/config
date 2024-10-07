{ inputs, ... }: {

  home = {
    sessionPath = [ "/opt/homebrew/bin" ];
    file.".hushlogin".text = "";
  };
}
