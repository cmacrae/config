{ stdenv, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "kubectl-argo-rollouts";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "argoproj";
    repo = "argo-rollouts";
    rev = "v${version}";
    sha256 = "0g9lj5q884b06znzbmn542mxkxid5aybzj2m3dvrwzcypsxrk32s";
  };

  subPackages = [ "cmd/kubectl-argo-rollouts" ];

  vendorSha256 = "079q9x7f35fzn8b2jd3ny3flvc70pv0yqkj3v9rkkqq4jp27a55x";

  meta = with stdenv.lib; {
    description = "kubectl plugin for Argo Rollouts";
    homepage = "https://github.com/argoproj/argo-rollouts";
    license = licenses.asl20;
  };
}
