{ stdenv, fetchFromGitHub, Carbon, Cocoa, ScriptingBridge }:

stdenv.mkDerivation rec {
  pname = "limelight";
  version = "4df5e0169cd4055b2150ca0dc8c9eef6a066cda5";

  src = fetchFromGitHub {
    owner = "koekeishiya";
    repo = pname;
    rev = version;
    sha256 = "0xai7vw0p1nm00r5p5yqpaqkvbgy4hf88wsjb2963lcgwsja3bs0";
  };

  buildInputs = [ Carbon Cocoa ScriptingBridge ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/man/man1/
    cp ./bin/limelight $out/bin/limelight
    cp ./doc/limelight.1 $out/share/man/man1/limelight.1
  '';

  meta = with stdenv.lib; {
    description = ''
      Standalone port of the yabai v2.4.3 border implementation 
    '';
    homepage = "https://github.com/koekeishiya/limelight";
    platforms = platforms.darwin;
    maintainers = [ maintainers.cmacrae ];
    license = licenses.mit;
  };
}
