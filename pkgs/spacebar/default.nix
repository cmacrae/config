{ pkgs, stdenv, fetchFromGitHub, Carbon, Cocoa, ScriptingBridge, ... }:

stdenv.mkDerivation rec {
  pname = "spacebar";
  version = "v0.4.0";

  # src = fetchFromGitHub {
  #   owner = "somdoron";
  #   repo = "spacebar";
  #   rev = "${version}";
  #   sha256 = "0wg3lfvxa4bnlhyw89kr97c1p2x5d1n55iapbfdcckq1yaxb257b";
  # };

  # TODO: [Darwin|spacebar] Local development - awaiting PR:
  #       https://github.com/somdoron/spacebar/pull/4
  src = ../../../spacebar;

  buildInputs = [ Carbon Cocoa ScriptingBridge ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/man/man1/
    cp ./bin/spacebar $out/bin/spacebar
    cp ./doc/spacebar.1 $out/share/man/man1/spacebar.1
  '';

  meta = with stdenv.lib; {
    description = ''
      A status bar for yabai tiling window management.
    '';
    homepage = https://github.com/somdoron/spacebar;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ cmacrae ];
    license = licenses.mit;
  };
}
