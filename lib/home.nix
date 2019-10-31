{ config, lib, pkgs, ... }:

let
  kubeTmux = pkgs.fetchFromGitHub {
    owner = "jonmosco";
    repo = "kube-tmux";
    rev = "7f196eeda5f42b6061673825a66e845f78d2449c";
    sha256 = "1dvyb03q2g250m0bc8d2621xfnbl18ifvgmvf95nybbwyj2g09cm";
  };

  tmuxYank = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-yank";
    rev = "ce21dafd9a016ef3ed4ba3988112bcf33497fc83";
    sha256 = "04ldklkmc75azs6lzxfivl7qs34041d63fan6yindj936r4kqcsp";
  };

  tmuxFpp = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-fpp";
    rev = "ca125d5a9c80bb156ac114ac3f3d5951a795c80e";
    sha256 = "1b89s6mfzifi7s5iwf22w7niddpq28w48nmqqy00dv38z4yga5ws";
  };

in with pkgs.stdenv; {
  environment.systemPackages = [ pkgs.zsh ];
  users.users.cmacrae.shell = pkgs.zsh;
  users.users.cmacrae.home = if isDarwin then
    "/Users/cmacrae"
    else
    "/home/cmacrae";

  home-manager.users.cmacrae = {
    home.packages = import ./packages.nix { inherit pkgs; };

    home.sessionVariables = {
      PAGER = "less -R";
      EDITOR = "emacsclient";
      GDK_SCALE = "-1";
    };

    programs.emacs.enable = true;
    services.emacs.enable = if isDarwin then false else true;

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;

    programs.browserpass.enable = true;
    programs.browserpass.browsers = [ "chrome" "chromium" ];

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "emacs";
      sessionVariables = { RPROMPT = ""; };

      shellAliases = {
        k = "kubectl";
        kp = "kube-prompt";
        kc = "kubectx";
        kn = "kubens";
      };

      oh-my-zsh.enable = true;

      plugins = [
        {
          name = "autopair";
          file = "autopair.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "4039bf142ac6d264decc1eb7937a11b292e65e24";
            sha256 = "02pf87aiyglwwg7asm8mnbf9b2bcm82pyi1cj50yj74z4kwil6d1";
          };
        }
        {
          name = "fast-syntax-highlighting";
          file = "fast-syntax-highlighting.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "zdharma";
            repo = "fast-syntax-highlighting";
            rev = "v1.28";
            sha256 = "106s7k9n7ssmgybh0kvdb8359f3rz60gfvxjxnxb4fg5gf1fs088";
          };
        }
        {
          name = "pi-theme";
          file = "pi.zsh-theme";
          src = pkgs.fetchFromGitHub {
            owner = "tobyjamesthomas";
            repo = "pi";
            rev = "96778f903b79212ac87f706cfc345dd07ea8dc85";
            sha256 = "0zjj1pihql5cydj1fiyjlm3163s9zdc63rzypkzmidv88c2kjr1z";
          };
        }
        {
          name = "z";
          file = "zsh-z.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "agkozak";
            repo = "zsh-z";
            rev = "41439755cf06f35e8bee8dffe04f728384905077";
            sha256 = "1dzxbcif9q5m5zx3gvrhrfmkxspzf7b81k837gdb93c4aasgh6x6";
          };
        }
      ];
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
        set -g status-left "#(${pkgs.bash}/bin/bash ${kubeTmux}/kube.tmux 250 green colour3)  "
        set -g status-right-length 100
        set -g status-right "#[fg=red,bg=default] %b %d #[fg=blue,bg=default] %R "
        set -g status-bg default
        setw -g window-status-format "#[fg=blue,bg=black] #I #[fg=blue,bg=black] #W "
        setw -g window-status-current-format "#[fg=blue,bg=default] #I #[fg=red,bg=default] #W "

        run-shell ${tmuxYank}/yank.tmux
        run-shell ${tmuxFpp}/fpp.tmux
      '';
    };

    home.file."Library/KeyBindings/DefaultKeyBinding.dict".text =  lib.optionalString isDarwin ''
      {
          /* Ctrl shortcuts */
          "^l"        = "centerSelectionInVisibleArea:";  /* C-l          Recenter */
          "^/"        = "undo:";                          /* C-/          Undo */
          "^_"        = "undo:";                          /* C-_          Undo */
          "^ "        = "setMark:";                       /* C-Spc        Set mark */
          "^\@"       = "setMark:";                       /* C-@          Set mark */
          "^w"        = "deleteToMark:";                  /* C-w          Delete to mark */

          /* Meta shortcuts */
          "~f"        = "moveWordForward:";               /* M-f          Move forward word */
          "~b"        = "moveWordBackward:";              /* M-b          Move backward word */
          "~<"        = "moveToBeginningOfDocument:";     /* M-<          Move to beginning of document */
          "~>"        = "moveToEndOfDocument:";           /* M->          Move to end of document */
          "~v"        = "pageUp:";                        /* M-v          Page Up */
          "~/"        = "complete:";                      /* M-/          Complete */
          "~c"        = ( "capitalizeWord:",              /* M-c          Capitalize */
                          "moveForward:",
                          "moveForward:");
          "~u"        = ( "uppercaseWord:",               /* M-u          Uppercase */
                          "moveForward:",
                          "moveForward:");
          "~l"        = ( "lowercaseWord:",               /* M-l          Lowercase */
                          "moveForward:",
                          "moveForward:");
          "~d"        = "deleteWordForward:";             /* M-d          Delete word forward */
          "^~h"       = "deleteWordBackward:";            /* M-C-h        Delete word backward */
          "~\U007F"   = "deleteWordBackward:";            /* M-Bksp       Delete word backward */
          "~t"        = "transposeWords:";                /* M-t          Transpose words */
          "~\@"       = ( "setMark:",                     /* M-@          Mark word */
                          "moveWordForward:",
                          "swapWithMark");
          "~h"        = ( "setMark:",                     /* M-h          Mark paragraph */
                          "moveToEndOfParagraph:",
                          "swapWithMark");

          /* C-x shortcuts */
          "^x" = {
              "u"     = "undo:";                          /* C-x u        Undo */
              "k"     = "performClose:";                  /* C-x k        Close */
              "^f"    = "openDocument:";                  /* C-x C-f      Open (find file) */
              "^x"    = "swapWithMark:";                  /* C-x C-x      Swap with mark */
              "^m"    = "selectToMark:";                  /* C-x C-m      Select to mark*/
              "^s"    = "saveDocument:";                  /* C-x C-s      Save */
              "^w"    = "saveDocumentAs:";                /* C-x C-w      Save as */
          };
      }
    '';
  };
}
