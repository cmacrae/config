{ stdenv, buildGoPackage, fetchFromGitHub, vmnet, ... }:
let
  owner = "machine-drivers";
  repo = "docker-machine-driver-hyperkit";

in buildGoPackage rec {
  name = "docker-machine-driver-hyperkit-${version}";
  version = "v1.0.0";

  buildInputs = [ vmnet ];

  goPackagePath = "github.com/${owner}/${repo}";

  src = fetchFromGitHub {
    inherit owner;
    inherit repo;

    rev = version;
    sha256 = "1asb3ry8h1dwpc7jpph6fcswaw74x8jqjf07n2bk6j1y8n17rjcv";
  };

  goDeps = ./deps.nix; 

  meta = with stdenv.lib; {
    description = "Docker Machine driver for hyperkit";
    homepage = "https://github.com/${owner}/${repo}";
    platforms = platforms.darwin;
    maintainers = with maintainers; [ cmacrae ];
    license = licenses.asl20;
  };
}
