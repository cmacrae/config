{
  lib,
  stdenv,
  trivialBuild,
  initFiles,
  emacs-all-the-icons-fonts,
  aspell,
  aspellDicts,
  ripgrep,
  lndir,
}:
let
  init = trivialBuild {
    pname = "config-init";
    version = "1";

    src = initFiles;

    buildPhase = ''
      runHook preBuild

      export HOME="$(mktemp -d)"

      mkdir -p "$HOME/.emacs.d"
      emacs --batch --quick \
        --eval '(setq byte-compile-error-on-warn t)' \
	--eval '(setq byte-compile-warnings '"'"'(not docstrings))' \
        --funcall batch-byte-compile \
        *.el

      runHook postBuild
    '';

    # Temporary hack because the Emacs native load path is not respected.
    fixupPhase = ''
      if [ -d "$HOME/.emacs.d/eln-cache" ]; then
        mv $HOME/.emacs.d/eln-cache/* $out/share/emacs/native-lisp
      fi
    '';
  };
in
stdenv.mkDerivation {
  name = "emacs-config";

  dontUnpack = true;

  buildInputs = [
    aspell
    aspellDicts.en
    emacs-all-the-icons-fonts
    ripgrep
  ];

  passthru.components = {
    inherit init;
  };

  installPhase = ''
    mkdir -p $out
    ${lndir}/bin/lndir -silent ${init}/share/emacs/site-lisp $out

    if [ -d "${init}/share/emacs/native-lisp" ]; then
      mkdir -p $out/eln-cache
      ${lndir}/bin/lndir -silent ${init}/share/emacs/native-lisp $out/eln-cache
    fi
  '';
}
