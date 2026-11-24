{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # OpenTofu only. The main nixpkgs pin is deliberately old (it fixes the
    # Hugo version that renders the live site), but it predates OpenTofu
    # 1.10 and therefore the S3 backend's native `use_lockfile` locking.
    # Bumping the main pin instead would also bump Hugo, which risks
    # changing the rendered output of a production site.
    nixpkgs-tofu.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-tofu, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsTofu = nixpkgs-tofu.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            gnumake
            git
            git-crypt
            hugo
            awscli
            poppler
            pkgsTofu.opentofu
          ];
        };
      }
    );
}
