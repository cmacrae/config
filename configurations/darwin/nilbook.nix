{ pkgs, inputs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "nilbook";

  system.activationScripts.extraActivation.text = ''
    if [ ! -d "/Library/Apple/usr/share/rosetta" ]; then
      echo "Installing Rosetta..."
      softwareupdate --install-rosetta --agree-to-license
    fi
  '';

  homebrew.casks = [
    "loom"
    "slack"
    "zoom"
  ];

  # NOTE: For post-build-hook scripts to be able to sign cache uploads
  # FIXME: Broken on aarch64-darwin atm, due to tests failing
  # environment.systemPackages = [ pkgs.awscli2 ];
  homebrew.brews = [ "awscli" ];
  environment.systemPackages = [
    (pkgs.runCommand "awscli2-homebrew-link" { } ''
      mkdir -p $out/bin
      ln -s /opt/homebrew/bin/aws $out/bin/aws
    '')
  ];

  programs.ssh.extraConfig = ''
    Host nix-build-*.*.internal
      User root
      IdentityAgent /tmp/yubikey-agent.sock
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  '';

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "nix-build-x86_64.platform.internal";
        sshUser = "root";
        systems = [ "x86_64-linux" ];
        maxJobs = 8;
      }
      {
        hostName = "nix-build-aarch64.platform.internal";
        sshUser = "root";
        systems = [ "aarch64-linux" ];
        maxJobs = 8;
      }
    ];
    settings = {
      builders-use-substitutes = true;
    };
  };

  home-manager.users.cmacrae =
    let
      primaryKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBF8LhNwEK9s/38T3I2zkWqZydYdChEb9xA3uzmETboDIy5nvRnLKT2p4ds7GELStes4PvGYqOLaVfp4SGYmjCLg=";
      secondaryKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNn7fjPQH+J9vL81DEDMx6w3pnVh77hgaU/9VYJyAzl/kUjOCDjBFv0aEArBVO+fafyvlSe9xuZKItQobPEKQbw=";
    in

    {
      imports = [
        inputs.limani.homeModules.default
        inputs.limani.homeModules.podman
      ];

      home.packages = with pkgs; [
        nodejs_latest
        ssm-session-manager-plugin
        telegram-desktop
        terraform-ls
        nodePackages.bash-language-server

        # NOTE: Used as the value of `credential_process` in
        #       ~/.aws/config's 'default' profile
        (pkgs.writeShellApplication {
          name = "aws-credentials-1password";
          runtimeInputs = [
            pkgs._1password
            pkgs.jq
          ];
          text = ''
            op item get AWS \
              --vault Employee \
              --fields "label=access key id,label=secret access key" \
              --format json | \
            jq -r '{
              Version: 1,
              AccessKeyId: (map(select(.label == "access key id")) | .[0].value),
              SecretAccessKey: (map(select(.label == "secret access key")) | .[0].value)
            }'
          '';
        })
      ];

      programs.limani.enable = true;
      # Wrap limactl to help it find guest agents
      programs.limani.package = pkgs.lima.overrideAttrs (o: {
        postFixup = (o.postFixup or "") + ''
          wrapProgram $out/bin/limactl \
            --run 'export LIMA_AGENT_SEARCH_PATH="${placeholder "out"}/share/lima:${placeholder "out"}/bin"'
        '';

        nativeBuildInputs = (o.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

        postInstall = (o.postInstall or "") + ''
          if [ -d "share/lima" ]; then
            mkdir -p $out/share/lima
            cp -r share/lima/* $out/share/lima/
          fi

          if [ -d "_output/share/lima" ]; then
            mkdir -p $out/share/lima
            cp -r _output/share/lima/* $out/share/lima/
          fi
        '';
      });

      programs.limani.podman.enable = true;
      programs.limani.podman.rosetta.enable = true;
      programs.limani.podman.args = [
        "--cpus 8"
        "--memory 8"
        "--mount-writable"
      ];

      programs.git.includes = [
        {
          condition = "hasconfig:remote.*.url:git@github.com:NillionNetwork/**";
          contents.user.signingkey = "key::${primaryKey}";
        }
      ];

      home.file.".ssh/allowed_signers".text = pkgs.lib.mkAfter ''
        * ${primaryKey}
        * ${secondaryKey}
      '';

      home.sessionVariables =
        let
          op = field: "$(op --account my read 'op://Private/Shell Variables/${field}')";
        in
        {
          CONTEXT7_API_KEY = op "context7 api key";
          NIX_CONFIG = ''access-tokens = github.com=${op "nix github pat"}'';
        };
    };
}
