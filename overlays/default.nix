self: super: {
  Emacs = super.callPackage ./emacs {
    inherit (super.darwin.apple_sdk.frameworks) AppKit GSS ImageIO;
    stdenv = super.clangStdenv;
  };

  Firefox = super.callPackage ./firefox {};

  hyperkit = super.callPackage ./hyperkit {
    inherit (super.darwin.apple_sdk.frameworks) Hypervisor vmnet SystemConfiguration;
    inherit (super.darwin.apple_sdk.libs) xpc;
    inherit (super.darwin) libobjc dtrace;
  };

  docker-machine-driver-hyperkit = super.callPackage ./docker-machine-driver-hyperkit {
    inherit (super.darwin.apple_sdk.frameworks) vmnet;
  };

  # NOTE: Following master until the new border implementation is released
  #       https://github.com/koekeishiya/yabai/issues/565
  yabai = super.yabai.overrideAttrs (o: {
    version = "master";
    src = super.fetchFromGitHub {
      owner = "koekeishiya";
      repo = "yabai";
      rev = "00cf49ce20d2dd95a3d550a5425cbecea3d14c9c";
      sha256 = "1lgiqq4x0vzczdn87kchp1dnbx296xamjabgv173gz1b7l3ar1pz";
    };
  });
}
