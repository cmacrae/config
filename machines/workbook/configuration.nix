{
  imports = [ ../../modules/darwin.nix ];
  local.darwin.machine = "workbook";
  local.darwin.skhd.extraBindings = ''
    cmd + ctrl - f : open -n ~/.nix-profile/Applications/Firefox.app --args -P work
    cmd + shift + ctrl - f : open -n ~/.nix-profile/Applications/Firefox.app --args -P home

    cmd - up: yabai -m display --focus next
    cmd - down: yabai -m display --focus prev
    cmd +  ctrl - up: yabai -m window --display next
    cmd +  ctrl - down: yabai -m window --display prev
    cmd + shift + ctrl - up: yabai -m space --display next
    cmd + shift + ctrl - down: yabai -m space --display prev
  '';
}
