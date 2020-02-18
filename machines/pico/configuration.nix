{
  imports = [ ../../modules/darwin.nix ];
  local.darwin.machine = "pico";
  local.darwin.skhd.extraBindings = ''
    cmd + ctrl - f : ~/.nix-profile/Applications/Firefox.app/Contents/MacOS/firefox -P home
    cmd + shift + ctrl - f : ~/.nix-profile/Applications/Firefox.app/Contents/MacOS/firefox -P work
  '';
}
