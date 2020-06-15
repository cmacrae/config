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
      rev = "0690eb50c6e336345a1b1235b3e0baf0245b09d5";
      sha256 = "148gjjn50l2x2psp37i37bfxgv31hmwqz5ryj6mvz16isffdx37z";
    };
  });
}
