self: super: {
  Firefox = super.callPackage ./firefox {};

  yabai = super.yabai.overrideAttrs (o: {
    version = "master";
    src = super.fetchFromGitHub {
      owner = "koekeishiya";
      repo = "yabai";
      rev = "034717e9744ef308ebe626cca8fceafef367abbd";
      sha256 = "0j06g3cp1y00aa320g5vai2c48yssx062fmy66rhns658cmi5xqg";
    };
  });

  # NOTE: For local development
  spacebar = super.spacebar.overrideAttrs (o: {
    # src = "${builtins.getEnv("HOME")}/dev/personal/github.com/cmacrae/spacebar";
    src = /Users/cmacrae/dev/spacebar;
  });

  kubectl-argo-rollouts = super.callPackage ./kubectl-argo-rollouts { };
}
