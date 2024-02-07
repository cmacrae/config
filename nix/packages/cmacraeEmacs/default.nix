{ stdenv
, runCommand
, fetchFromGitHub
, emacs-nox
, emacs-pgtk
, emacsPackages
, emacsWithPackagesFromUsePackage
}:

let
  defaultInitFile = stdenv.mkDerivation {
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
  };

  # TODO: derive 'name' from assignment
  elPackage = name: src:
    runCommand "${name}-epkg" { } ''
      mkdir -p  $out/share/emacs/site-lisp
      cp -r ${src}/* $out/share/emacs/site-lisp/
    '';
in
emacsWithPackagesFromUsePackage {
  inherit defaultInitFile;

  alwaysEnsure = true;
  alwaysTangle = true;
  package = emacs-pgtk;

  config = ./readme.org;

  override = epkgs: epkgs // {
    copilot = elPackage "copilot" (fetchFromGitHub {
      owner = "zerolfx";
      repo = "copilot.el";
      rev = "ba1d6018fdc2d735fecab1b2dcd4b5ea121b05ac";
      sha256 = "0glbmgfznmqbq8nggdl2fsxf25wv3gav40m65g4637l0gyyyx0av";
    });

    nano-dialog = elPackage "nano-dialog" (fetchFromGitHub {
      owner = "rougier";
      repo = "nano-dialog";
      rev = "4127d8feceeed4ceabbe16190dae3f4609f2fdb4";
      hash = "sha256-R5+6Zwe8CMFEVg1RUSJT64lTDeHSsQ0FrDZRVA9tPIA=";
    });
  };
}
