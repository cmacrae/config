self: super: {
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

  # NOTE: For local development
  spacebar = super.spacebar.overrideAttrs (o: {
    # src = "${builtins.getEnv("HOME")}/dev/personal/github.com/cmacrae/spacebar";
    src = /Users/cmacrae/dev/personal/github.com/cmacrae/spacebar;
  });
}
