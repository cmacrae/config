{ stdenv, lib, fetchFromGitHub, Hypervisor, vmnet, SystemConfiguration, xpc, libobjc, dtrace }:

let
  version = "v0.20200224";
  rev = "97f091f9a65390123d96c6794a4b29190e04ce3d";
in
stdenv.mkDerivation rec {
  name    = "hyperkit-${version}";

  src = fetchFromGitHub {
    owner = "moby";
    repo = "hyperkit";
    inherit rev;
    sha256 = "1q9i88515nx5ls6ds870gliprznzvy8dsz0rllw42zcg2g8g7any";
  };

  buildInputs = [ Hypervisor vmnet SystemConfiguration xpc libobjc dtrace ];

  # Don't use git to determine version
  prePatch = ''
    substituteInPlace Makefile \
      --replace 'shell git describe --abbrev=6 --dirty --always --tags' "${version}" \
      --replace 'shell git rev-parse HEAD' "${rev}" \
      --replace 'PHONY: clean' 'PHONY:'
    make src/include/xhyve/dtrace.h
  '';

  makeFlags = [
   "CFLAGS+=-Wno-shift-sign-overflow"
   ''CFLAGS+=-DVERSION=\"${version}\"''
   ''CFLAGS+=-DVERSION_SHA1=\"${rev}\"''
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp build/hyperkit $out/bin
  '';

  meta = {
    description = "A toolkit for embedding hypervisor capabilities in your application";
    homepage = "https://github.com/moby/hyperkit";
    maintainers = [ lib.maintainers.puffnfresh ];
    platforms = lib.platforms.darwin;
    license = lib.licenses.bsd3;
  };
}
