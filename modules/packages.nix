{ pkgs }:

with pkgs; [
  awscli
  bc
  bind
  clang
  ffmpeg-full
  gnumake
  gnupg
  gnused
  htop
  hugo
  jq
  mpv
  nixops
  nix-prefetch-git
  nmap
  p7zip
  pass
  python3
  ranger
  ripgrep
  rsync
  terraform
  unzip
  up
  vim
  wget
  wireguard-tools
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

  # Docker
  docker
  docker-machine
  docker-machine-driver-hyperkit
  hyperkit

  # k8s
  kubectl
  kubectx
  kubeval
  kube-prompt
  kubernetes-helm
  kustomize
]
