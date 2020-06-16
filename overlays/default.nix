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
      rev = "7b9805c3a33693d691b7551d4cdee5242ad4dae6";
      sha256 = "01qqndawi4hl8lfvm11n7clla57hkrnck7k0hgsk6l62vyv26lj9";
    };
  });

  spacebar = super.spacebar.overrideAttrs (o: {
    version = "master";
    src = super.fetchFromGitHub {
      owner = "somdoron";
      repo = "spacebar";
      rev = "1670a26a9f09b10a6c8867e1bc1cda1c00c2f54c";
      sha256 = "1yk3ijn0kivb9ngf8wva6fbzla7152xhzjiad56hjww0avx9cq06";
    };
  });
}
