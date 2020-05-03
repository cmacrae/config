{ pkgs, stdenv, fetchFromGitHub, Carbon, Cocoa, ScriptingBridge, ... }:

stdenv.mkDerivation rec {
  pname = "spacebar";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "somdoron";
    repo = pname;
    rev = "v${version}";
    sha256 = "0v8v4xsc67qpzm859r93ggq7rr7hmaj6dahdlg6g3ppj81cq0khz";
  };

  # TODO: [Darwin|spacebar] Local development - awaiting PR:
  #       https://github.com/somdoron/spacebar/pull/4
  # src = ../../../spacebar;

  buildInputs = [ Carbon Cocoa ScriptingBridge ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/man/man1/
    cp ./bin/spacebar $out/bin/spacebar
    cp ./doc/spacebar.1 $out/share/man/man1/spacebar.1
  '';

  meta = with stdenv.lib; {
    description = "A status bar for yabai tiling window management";
    homepage = https://github.com/somdoron/spacebar;
    platforms = platforms.darwin;
    maintainers = [ maintainers.cmacrae ];
    license = licenses.mit;
  };
}
