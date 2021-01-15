self: super: {
  Firefox = super.callPackage ./firefox { };

  emacs-vterm = super.callPackage ./emacs-vterm { };

  # TODO: Switch back to src build when SkyLight issue is fixed
  yabai = super.yabai.overrideAttrs (o: rec {
    version = "3.3.6";
    src = builtins.fetchTarball {
      url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
      sha256 = "0a4yb1wisxhn7k8f9l4bp8swkb17qdkc4crh42zvz4lpaxg0sgxi";
    };

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/man/man1/
      cp ./bin/yabai $out/bin/yabai
      cp ./doc/yabai.1 $out/share/man/man1/yabai.1
    '';
  });

  # spacebar = super.spacebar.overrideAttrs (o: {
  #   src = "${builtins.getEnv("HOME")}/src/github.com/cmacrae/spacebar";
  # });
}
