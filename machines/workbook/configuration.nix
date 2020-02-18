{
  imports = [ ../../modules/darwin.nix ];
  local.darwin.machine = "workbook";
  local.darwin.skhd.extraBindings = ''
    cmd + ctrl - f : ~/.nix-profile/Applications/Firefox.app/Contents/MacOS/firefox -P work
    cmd + shift + ctrl - f : ~/.nix-profile/Applications/Firefox.app/Contents/MacOS/firefox -P home
  '';
}
