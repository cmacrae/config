let
  version = "73.0";

in

self: super: {
  Firefox = with super; stdenv.mkDerivation rec {
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
      sha256 = "0w2im76vri8wrx88qi66arhkwm3h7vyas9s3g0cbrkpsarf1hh82";
    };

    meta = with stdenv.lib; {
      description = "The Firefox web browser";
      homepage = https://www.mozilla.org/en-GB/firefox;
      maintainers = with maintainers; [ cmacrae ];
      platforms = platforms.darwin;
    };
  };
}
