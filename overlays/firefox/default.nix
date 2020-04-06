{ stdenv, fetchurl, undmg, unzip }:
let
  version = "75.0";

in

stdenv.mkDerivation rec {
  inherit version;
  
  name = "Firefox-${version}";
  buildInputs = [ undmg unzip ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
      mkdir -p "$out/Applications"
      cp -r Firefox.app "$out/Applications/Firefox.app"
    '';

  src = fetchurl {
    name = "Firefox-${version}.dmg";
    url = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/mac/en-GB/Firefox%20${version}.dmg";
    sha256 = "11hjxkr183aixnsiriw77fvsag29479asvzmgpml0258b93rc9sy";
  };

  meta = with stdenv.lib; {
    description = "The Firefox web browser";
    homepage = https://www.mozilla.org/en-GB/firefox;
    maintainers = with maintainers; [ cmacrae ];
    platforms = platforms.darwin;
  };
}
