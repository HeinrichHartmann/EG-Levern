{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    with nixpkgs.legacyPackages.x86_64-linux; {
      devShell.x86_64-linux = mkShell {
        buildInputs =  [
          gnumake
          git
          git-crypt
          hugo
        ];
      };
    };
}
