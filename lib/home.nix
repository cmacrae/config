{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;

in {
  users.users.cmacrae.shell = pkgs.zsh;
  home-manager.users.cmacrae = {
    home.packages = import ./packages.nix { inherit pkgs;};

    home.sessionVariables = {
      GOROOT = "${pkgs.go}/share/go";
      GOPATH = "/home/cmacrae/dev/go";
      PAGER = "less -R";
      EDITOR = "emacsclient";
    };

    programs.fzf.enable = true;
    programs.fzf.enableZshIntegration = true;

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "emacs";
      history = {
        extended = true;
        ignoreDups = true;
      };
      initExtra = ''
        autoload -Uz promptinit && promptinit
        autoload -Uz zutil
        autoload -Uz complist
        autoload -Uz colors && colors

        setopt   correct always_to_end notify
        setopt   nobeep autolist autocd print_eight_bit
        setopt   append_history share_history globdots
        setopt   pushdtohome cdablevars recexact longlistjobs
        setopt   autoresume histignoredups pushdsilent noclobber
        setopt   autopushd pushdminus extendedglob rcquotes
        unsetopt bgnice autoparamslash

        # Prompts
        if [[ ! -n $INSIDE_EMACS ]]; then
            export "PROMPT=
        %{$fg[red]%}$ %{$reset_color%}"
            export "RPROMPT=%{$fg[blue]%}%~%f%b"
        else
            export "PROMPT=
        %{$fg[blue]%}%~ %{$fg[red]%}$ %f%b"
        fi

        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        if [ "$(tty)" = "/dev/tty1" ]; then
           /run/current-system/sw/bin/sway
        fi
        
        # set TERM here to override any 'pollution'
        export TERM=screen-256color

        # for capturing video from webcam/audio from soundcard
        ffrecord() {
          ${pkgs.ffmpeg-full}/bin/ffmpeg -y -thread_queue_size 2048 \
          -f v4l2 -input_format h264 -video_size hd1080 \
          -i /dev/video2 -f alsa -thread_queue_size 130064 \
          -i plughw:CARD=CODEC,DEV=0 \
          -c:v libx264 -ar 44100 -crf 17 -c:a aac \
          $@
        }
      '';
    };

    programs.tmux = {
      enable = true;
      shortcut = "q";
      keyMode = "vi";
      clock24 = true;
      terminal = "screen-256color";
      customPaneNavigationAndResize = true;
      extraConfig = ''
        unbind [
        unbind ]
        
        bind ] next-window
        bind [ previous-window
        bind Escape copy-mode
        
        bind-key -r C-k resize-pane -U
        bind-key -r C-j resize-pane -D
        bind-key -r C-h resize-pane -L
        bind-key -r C-l resize-pane -R
        
        bind-key -r C-M-k resize-pane -U 5
        bind-key -r C-M-j resize-pane -D 5
        bind-key -r C-M-h resize-pane -L 5
        bind-key -r C-M-l resize-pane -R 5
        
        set -g pane-border-fg black
        set -g pane-active-border-fg red
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
        setw -g window-status-fg white
        setw -g window-status-attr none
        
        set -g status-left ""
        set -g status-right "#[fg=red,bg=default] %b %d #[fg=blue,bg=default] %R "
        set -g status-right-length 100
        set -g status-bg default
        setw -g window-status-format "#[fg=blue,bg=black] #I #[fg=blue,bg=black] #W "
        setw -g window-status-current-format "#[fg=blue,bg=default] #I #[fg=red,bg=default] #W "
      '';
    };
  };
}
