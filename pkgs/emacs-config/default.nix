{ stdenv, emacs-nox, emacsPackages }:

stdenv.mkDerivation {
  pname = "emacs-config";
  name = "default.el";

  src = ./.;

  buildInputs = [ emacs-nox emacsPackages.use-package ];

  preBuild = ''
    emacs --batch --quick \
    --load org readme.org \
    --funcall org-babel-tangle
  '';

  buildPhase = ''
    runHook preBuild

    emacs -L . \
      -L ${emacsPackages.use-package}/share/emacs/site-lisp \
      --batch \
      -f batch-byte-compile *.el

    runHook postBuild
  '';

  installPhase = ''
    cp readme.el $out
  '';
}
