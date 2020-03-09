{ pkgs, stdenv, fetchFromGitHub, Carbon, Cocoa, ScriptingBridge, ... }:

stdenv.mkDerivation rec {
  pname = "yabai";
  version = "v2.3.0";

  src = fetchFromGitHub {
    owner = "koekeishiya";
    repo = "yabai";
    rev = "${version}";
    sha256 = "0hjcl4gwsnkb89ymw3qqckc6194qsfzm1hbp63x8i0zn6mfwr3xc";
  };

  buildInputs = [ Carbon Cocoa ScriptingBridge ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/man/man1/
    cp ./bin/yabai $out/bin/yabai
    cp ./doc/yabai.1 $out/share/man/man1/yabai.1
  '';

  meta = with stdenv.lib; {
    description = ''
      A tiling window manager for macOS based on binary space partitioning.
    '';
    homepage = https://github.com/koekeishiya/yabai;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ cmacrae ];
    license = licenses.mit;
  };
}
