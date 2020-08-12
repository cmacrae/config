self: super: {
  Emacs = (super.emacsMacport.overrideAttrs (o: rec {
    version = "27.1";
    macportVersion = "8.0";
    emacsName = "emacs-${version}";

    src = builtins.fetchurl {
      url = "http://mirror.koddos.net/gnu/emacs/${emacsName}.tar.xz";
      sha256 = "0h9f2wpmp6rb5rfwvqwv1ia1nw86h74p7hnz3vb3gjazj67i4k2a";
    };

    macportSrc = builtins.fetchurl {
      url = "ftp://ftp.math.s.chiba-u.ac.jp/emacs/${emacsName}-mac-${macportVersion}.tar.gz";
      sha256 = "0rjk82k9qp1g701pfd4f0q2myzvsnp9q8xzphlxwi5yzwbs91kjq";
    };

    doCheck = false;
    installTargets = [ "tags" "install" ];
    buildInputs = o.buildInputs ++ [ super.jansson ];
    configureFlags = o.configureFlags ++ [ "--with-json" ];

    patches = [];
  }));

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
