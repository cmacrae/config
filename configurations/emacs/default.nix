{ inputs, pkgs }:
let
  inherit (pkgs) lib;
  inherit (inputs) self;
  org = inputs.org-babel.lib;
  emacsPackage = pkgs.emacs-pgtk;

  treeSitterLoadPath = lib.pipe pkgs.tree-sitter-grammars [
    (lib.filterAttrs (name: _: name != "recurseForDerivations"))
    builtins.attrValues
    (map (drv: {
      # Some grammars don't contain "tree-sitter-" as the prefix,
      # so add it explicitly.
      name = "libtree-sitter-${
          lib.pipe (lib.getName drv) [
            (lib.removeSuffix "-grammar")
            (lib.removePrefix "tree-sitter-")
          ]
        }${pkgs.stdenv.targetPlatform.extensions.sharedLibrary}";
      path = "${drv}/parser";
    }))
    (pkgs.linkFarm "treesit-grammars")
  ];
in

(inputs.twist.lib.makeEnv {
  inherit emacsPackage pkgs;

  lockDir = ./.lock;
  initFiles = [
    (pkgs.tangleOrgBabelFile "init.el" ./README.org {
      processLines = org.excludeHeadlines (org.tag "early");
    })
  ];

  exportManifest = true;
  configurationRevision =
    "${builtins.substring 0 8 self.lastModifiedDate}.${
      if self ? rev then builtins.substring 0 7 self.rev else "dirty"
    }";

  inputOverrides = import ./input-overrides.nix { inherit (pkgs) lib; };

  extraSiteStartElisp = ''
    (add-to-list 'treesit-extra-load-path "${treeSitterLoadPath}/")
  '';

  registries = import ./registries.nix {
    inherit inputs;
    emacsSrc = emacsPackage.src;
  };
}).overrideScope (
  _: prev': {
    elispPackages = prev'.elispPackages.overrideScope (
      pkgs.callPackage ./package-overrides.nix { inherit (prev') emacs; }
    );
  }
)
