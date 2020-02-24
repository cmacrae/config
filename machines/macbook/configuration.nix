{
  imports = [ ../../modules/darwin.nix ];
  local.darwin.machine = "macbook";
  local.darwin.skhd.extraBindings = ''
    cmd + ctrl - f : open  -n ~/.nix-profile/Applications/Firefox.app --args -P home
    cmd + shift + ctrl - f : open -n ~/.nix-profile/Applications/Firefox.app --args -P work
  '';
}
