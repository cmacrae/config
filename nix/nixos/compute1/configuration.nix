{ inputs, ... }: {
  imports = [
    inputs.self.nixosModules.common
    inputs.self.nixosModules.compute
    inputs.self.nixosModules.server
  ];

  system.stateVersion = "21.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  compute.id = 1;
  compute.hostId = "ef32e32d";
  compute.efiBlockId = "9B1E-7DE0";

  services.nzbget.enable = true;
  services.nzbget.user = "admin";
  services.nzbget.group = "admin";
}
