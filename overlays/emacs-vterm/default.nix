{ stdenv, fetchFromGitHub, cmake, libtool, glib, libvterm-neovim, ncurses }:

stdenv.mkDerivation rec {
  pname = "emacs-vterm";
  version = "master";

  src = fetchFromGitHub {
    owner = "akermu";
    repo = "emacs-libvterm";
    rev = "9d2ef5e535e79781a0c1d2523f82d096eb48765f";
    sha256 = "03nslg391cagq9kdxkgyjcw3abfd5xswza5bq8rl8mrp9f8v7i17";
  };

  nativeBuildInputs = [
    cmake
    libtool
    glib.dev
  ];

  buildInputs = [
    glib.out
    libvterm-neovim
    ncurses
  ];

  cmakeFlags = [
    "-DUSE_SYSTEM_LIBVTERM=yes"
  ];

  preConfigure = ''
    echo "include_directories(\"${glib.out}/lib/glib-2.0/include\")" >> CMakeLists.txt
    echo "include_directories(\"${glib.dev}/include/glib-2.0\")" >> CMakeLists.txt
    echo "include_directories(\"${ncurses.dev}/include\")" >> CMakeLists.txt
    echo "include_directories(\"${libvterm-neovim}/include\")" >> CMakeLists.txt
  '';

  installPhase = ''
    mkdir -p $out
    cp ../vterm-module.so $out
    cp ../vterm.el $out
  '';
}
