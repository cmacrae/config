{
  imports = [ ../../modules/darwin.nix ];
  local.darwin.machine = "macbook";
  local.darwin.skhd.extraBindings = ''
    cmd + ctrl - f : ~/.nix-profile/Applications/Firefox.app/Contents/MacOS/firefox -P home
    cmd + shift + ctrl - f : ~/.nix-profile/Applications/Firefox.app/Contents/MacOS/firefox -P work
  '';
}
