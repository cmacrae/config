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
      rev = "0c6157e52bc29cac4ffe46003b157fc2319391ee";
      sha256 = "06a3dvkmbpaig0blf752v9w4bcs8glsz54iicz9bdrlpl9q0aykw";
    };

    # TODO: Remove once unstable has caught up.
    buildInputs = o.buildInputs ++ [ super.xxd ];
  });

  # NOTE: Following my fork with enhancements
  #       (submitted upstream for consideration)
  #       - No underlines
  #       - Current space icon indicator with colour option
  spacebar = super.spacebar.overrideAttrs (o: {
    version = "enhanced";
    # src = /Users/cmacrae/dev/personal/github.com/cmacrae/spacebar;
    src = super.fetchFromGitHub {
      owner = "cmacrae";
      repo = "spacebar";
      rev = "refs/heads/enhancements";
      sha256 = "1r8pjw2v726fkjichc6sfin9cr2mn8hqb4l7dlxn9g4vk6nzbxnx";
    };
  });
}
