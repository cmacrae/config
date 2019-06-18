{ pkgs }:

with pkgs; [
  ansible
  bc
  bind
  emacs
  ffmpeg-full
  git
  gnumake
  gnupg
  htop
  jq
  lame
  mpv
  nixops
  nix-prefetch-git
  nmap
  p7zip
  pass
  ranger
  ripgrep
  rsync
  terraform
  up
  vim
  youtube-dl

  # Go
  go
  gocode
  godef
  gotools
  golangci-lint
  golint
  go2nix
  errcheck
  gotags
]
