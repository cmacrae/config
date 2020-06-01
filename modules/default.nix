let
  hm = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;

in {
  darwin       = ./darwin.nix;
  home         = ./home.nix;
  home-manager = "${hm}/nix-darwin";
  limelight    = ./limelight.nix;
}
