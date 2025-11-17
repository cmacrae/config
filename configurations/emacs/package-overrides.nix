{
  cmake,
  emacs,
  gcc,
  git,
  libvterm-neovim,
  python3,
}:
_final: prev: {
  forge = prev.forge.overrideAttrs (o: {
    nativeBuildInputs = (o.nativeBuildInputs or [ ]) ++ [ git ];
  });

  treemacs = prev.treemacs.overrideAttrs (o: {
    buildInputs = o.buildInputs ++ [
      git
      python3
    ];
  });

  vterm = prev.vterm.overrideAttrs (o: {
    nativeBuildInputs = [
      cmake
      gcc
    ];
    buildInputs = o.buildInputs ++ [ libvterm-neovim ];
    cmakeFlags = [ "-DEMACS_SOURCE=${emacs.src}" ];

    # Build vterm module before byte-compilation to avoid interactive prompt
    preBuild = ''
      mkdir -p build
      cd build
      cmake ..
      make
      install -m444 -t . ../*.so
      install -m600 -t . ../*.el
      cp -r -t . ../etc
      rm -rf {CMake*,build,*.c,*.h,Makefile,*.cmake}
      cd ..

      export TERM=dumb
    '';
  });
}
