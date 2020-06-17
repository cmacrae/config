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

  yabai = super.yabai.overrideAttrs (o: {
    version = "master";
    src = super.fetchFromGitHub {
      owner = "koekeishiya";
      repo = "yabai";
      rev = "a4c0115defa77981052bebca441c8afc2b31a448";
      sha256 = "063lwb5jby8i8n8lmzdll313zdiy9q1b2qxcrbb2hrk1y70v22f1";
    };
  });

  # NOTE: Following my fork with enhancements
  #       (submitted upstream for consideration)
  spacebar = super.spacebar.overrideAttrs (o: {
    version = "enhanced";
    src = super.fetchFromGitHub {
      owner = "cmacrae";
      repo = "spacebar";
      rev = "9e5d235d04b00d93d5df70a08caddf4983570584";
      sha256 = "0cixlizzsgj0c43n8bi670pid9kd92v4kjxxazbv49vka275aaz5";
    };
  });
}
