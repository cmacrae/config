{ inputs }:
final: prev:
let
  inherit (prev) lib;
  org = inputs.org-babel.lib;
  emacsPackage = final.emacs-pgtk;

  treeSitterLoadPath = lib.pipe final.tree-sitter-grammars [
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
        }${prev.stdenv.targetPlatform.extensions.sharedLibrary}";
      path = "${drv}/parser";
    }))
    (prev.linkFarm "treesit-grammars")
  ];
in
{
  # FIXME: manually implemented ~/.config/nix/nix.conf with gh access token
  #        for rate limiting. see if this is something we can create with
  #        age/age-rekey/homeage
  emacs-env =
    (final.emacsTwist {
      inherit emacsPackage;

      lockDir = ./.lock;
      initFiles = [
        # (final.tangleOrgBabelFile "early-init.el" ./README.org {
        #   processLines = org.selectHeadlines (org.tag "early");
        # })
        # (final.tangleOrgBabelFile "init.el" ./README.org {
        #   processLines = org.excludeHeadlines (org.tag "early");
        # })
        (final.tangleOrgBabelFile "init.el" ./README.org {
          processLines = org.excludeHeadlines (org.tag "DISABLED");
        })

      ];
      extraOutputsToInstall = [ "Applications" ];
      inputOverrides = import ./input-overrides.nix { inherit (inputs.nixpkgs) lib; };

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
          prev.callPackage ./package-overrides.nix { inherit (prev') emacs; }
        );
      }
    );

  emacs-config = prev.callPackage ./. {
    inherit (final.emacs-env) initFiles;
    trivialBuild = final.emacsPackages.trivialBuild.override {
      emacs = final.emacs-env.overrideScope (
        _: prev': { inherit (prev'.emacs) meta withNativeCompilation; }
      );
    };
  };
}
