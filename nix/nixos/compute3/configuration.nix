{ inputs, ... }: {
  imports = [
    inputs.self.nixosModules.common
    inputs.self.nixosModules.compute
    inputs.self.nixosModules.server
  ];

  system.stateVersion = "21.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  compute.id = 3;
  compute.hostId = "11dc35bc";
  compute.efiBlockId = "A181-EEC7";

  services.plex.enable = true;
  services.plex.user = "admin";
  services.plex.group = "admin";
}
