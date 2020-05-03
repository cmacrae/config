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

  yabai = super.callPackage ./yabai {
    inherit (super.darwin.apple_sdk.frameworks)
      Carbon Cocoa ScriptingBridge;
  };

  spacebar = super.callPackage ./spacebar {
    inherit (super.darwin.apple_sdk.frameworks)
      Carbon Cocoa ScriptingBridge;
  };

  skhd = super.skhd.overrideAttrs (o: {
    src = super.fetchFromGitHub {
      owner = "koekeishiya";
      repo = "skhd";
      rev = "v0.3.5";
      sha256 = "0x099979kgpim18r0vi9vd821qnv0rl3rkj0nd1nx3wljxgf7mrg";
    };
  });
}
