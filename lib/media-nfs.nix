{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ nfs-utils ];
  services.rpcbind.enable = true;
  users.groups.media.gid = 1005;
  users.users.media = {
    description = "Media Management";
    isNormalUser = true;
    group = "media";
    uid = 1005;
  };

  fileSystems."/media/movies" = {
    device = "the-ark:/export/media/movies";
    fsType = "nfs";
  };

  fileSystems."/media/tv" = {
    device = "the-ark:/export/media/tv";
    fsType = "nfs";
  };

  fileSystems."/media/downloads" = {
    device = "the-ark:/export/media/downloads";
    fsType = "nfs";
  };
}
