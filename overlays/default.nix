self: pkgs: {
  Firefox = pkgs.callPackage ./firefox {};

  hyperkit = pkgs.callPackage ./hyperkit {
    inherit (pkgs.darwin.apple_sdk.frameworks) Hypervisor vmnet SystemConfiguration;
    inherit (pkgs.darwin.apple_sdk.libs) xpc;
    inherit (pkgs.darwin) libobjc dtrace;
  };

  docker-machine-driver-hyperkit = pkgs.callPackage ./docker-machine-driver-hyperkit {
    inherit (pkgs.darwin.apple_sdk.frameworks) vmnet;
  };
}
