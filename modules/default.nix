{
  macintosh    = ./macintosh.nix;
  home-manager = "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nix-darwin";
}
