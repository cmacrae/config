{ pkgs }:

with pkgs; [
  ansible
  bc
  bind
  ffmpeg-full
  gnumake
  gnupg
  htop
  jq
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
  unzip
  up
  vim
  wget
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

  # k8s
  kubectl
  kubectx
  kube-prompt
  fluxctl
  kubernetes-helm
  kustomize
]
