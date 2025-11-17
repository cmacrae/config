{
  osConfig,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in
{
  imports = [
    inputs.twist.homeModules.emacs-twist
  ];

  # FIXME: disabling while we're tracking unstable home-manager.
  #        remove this once we're back to tracking a release - see note
  #        in flake inputs.
  home.enableNixpkgsReleaseCheck = false;

  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    _1password-cli
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    bc
    claude-code
    claude-code-acp
    cocoapods
    ffmpeg
    gnumake
    gnupg
    gnused
    htop
    jq
    just
    mpv
    nixd
    nixfmt-rfc-style
    nix-prefetch-git
    nmap
    pass
    podman
    python311
    python311Packages.python-lsp-server
    pwgen
    ranger
    ripgrep
    rsync
    ruby
    ruff
    sourcekit-lsp
    ty
    unzip
    up
    wget
    yt-dlp
    yubikey-manager
  ];

  home.shell.enableBashIntegration = true;
  home.shell.enableZshIntegration = true;

  home.sessionVariables = mkMerge [
    {
      PAGER = "less -FR";
      EDITOR = "emacsclient";
    }
    (mkIf isDarwin {
      PATH = "$PATH:/opt/homebrew/bin";
      LC_ALL = "en_GB.UTF-8";
    })
  ];

  services.yubikey-agent.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = osConfig.users.users.cmacrae.description;
    userEmail = "hi@cmacr.ae";
    extraConfig = {
      github.user = "cmacrae";
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      user.signingkey = "key::ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHiZYIZ2NSdSvI2aZKDSv1OV9NiXRkQmagsW59vl+/WzObf16IbQLfCmtZePt6rdW7584xgdoZos4ivSk/g+Fdk=";
    };
  };

  home.file.".ssh/allowed_signers".text =
    "* ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHiZYIZ2NSdSvI2aZKDSv1OV9NiXRkQmagsW59vl+/WzObf16IbQLfCmtZePt6rdW7584xgdoZos4ivSk/g+Fdk=";

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.ghostty = {
    enable = true;
    package =
      # NOTE: ghostty install is handled via homebrew since it's not
      #       packaged for aarch64-darwin yet
      if isDarwin then null else pkgs.ghostty;

    settings = {
      theme = "light:dawnfox,dark:duskfox";
      cursor-style = "block";
      macos-option-as-alt = true;
      mouse-hide-while-typing = true;
      macos-auto-secure-input = true;
      macos-titlebar-style = "hidden";
      auto-update = "off";
      shell-integration = "detect";
      quick-terminal-position = "center";
      quick-terminal-animation-duration = 0;
      quick-terminal-size = "80%";
      clipboard-read = "allow";
      clipboard-write = "allow";
      window-padding-x = 20;
      window-padding-y = 10;
      initial-window = false;
      quit-after-last-window-closed = false;
      background-opacity = 0.85;
      background-blur = true;

      keybind = [
        "global:cmd+ctrl+grave_accent=toggle_quick_terminal"
      ];
    };
  };

  programs.emacs-twist = {
    enable = true;
    emacsclient.enable = true;
    config = inputs.self.packages.${pkgs.stdenv.system}.emacs-env;
    earlyInitFile = inputs.self.packages.${pkgs.stdenv.system}.emacs-early-init;
    createInitFile = true;
    createManifestFile = true;
    icons.enable = false;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";
    sessionVariables = {
      DIRENV_LOG_FORMAT = null;
    };

    shellAliases = {
      t = "cd $(mktemp -d)";
    };

    oh-my-zsh.enable = true;

    plugins = [
      {
        name = "autopair";
        file = "share/zsh/zsh-autopair/autopair.zsh";
        src = pkgs.zsh-autopair;
      }
      {
        name = "fast-syntax-highlighting";
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
        src = pkgs.zsh-fast-syntax-highlighting;
      }
    ];
  };

  programs.zoxide.enable = true;

  programs.carapace.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$character";

      directory = {
        style = "bold blue";
        truncation_length = 0;
        truncate_to_repo = true;
        home_symbol = "~";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      git_branch.disabled = true;
      git_status.disabled = true;
      package.disabled = true;
      nodejs.disabled = true;
      python.disabled = true;
      rust.disabled = true;
    };
  };

  programs.tmux = {
    enable = true;
    shortcut = "q";
    keyMode = "vi";
    clock24 = true;
    terminal = "screen-256color";
    customPaneNavigationAndResize = true;
    secureSocket = false;
    extraConfig = ''
      unbind [
      unbind ]

      bind ] next-window
      bind [ previous-window

      bind Escape copy-mode
      bind P paste-buffer
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
      set -g mouse on

      bind-key -r C-k resize-pane -U
      bind-key -r C-j resize-pane -D
      bind-key -r C-h resize-pane -L
      bind-key -r C-l resize-pane -R

      bind-key -r C-M-k resize-pane -U 5
      bind-key -r C-M-j resize-pane -D 5
      bind-key -r C-M-h resize-pane -L 5
      bind-key -r C-M-l resize-pane -R 5

      set -g display-panes-colour white
      set -g display-panes-active-colour red
      set -g display-panes-time 1000
      set -g status-justify left
      set -g set-titles on
      set -g set-titles-string 'tmux: #T'
      set -g repeat-time 100
      set -g renumber-windows on
      set -g renumber-windows on

      setw -g monitor-activity on
      setw -g automatic-rename on
      setw -g clock-mode-colour red
      setw -g clock-mode-style 24
      setw -g alternate-screen on

      set -g status-left-length 100
      # set -g status-left "#  "
      set -g status-right-length 100
      set -g status-right "#[fg=red,bg=default] %b %d #[fg=blue,bg=default] %R "
      set -g status-bg default
      setw -g window-status-format "#[fg=blue,bg=black] #I #[fg=blue,bg=black] #W "
      setw -g window-status-current-format "#[fg=blue,bg=default] #I #[fg=red,bg=default] #W "
    '';
  };
}
