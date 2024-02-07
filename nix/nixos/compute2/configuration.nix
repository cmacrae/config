{ inputs, ... }: {
  imports = [
    inputs.self.nixosModules.common
    inputs.self.nixosModules.compute
    inputs.self.nixosModules.server
  ];

  system.stateVersion = "21.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  compute.id = 2;
  compute.hostId = "7df67865";
  compute.efiBlockId = "0DDD-4E07";

  services.radarr.enable = true;
  services.radarr.user = "admin";
  services.radarr.group = "admin";

  services.sonarr.enable = true;
  services.sonarr.user = "admin";
  services.sonarr.group = "admin";

  services.prowlarr.enable = true;
}
