{
  description = "regexcite - Make Regular Expressions More Exciting";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        r-packages = with pkgs.rPackages; [
          stringr
          testthat
          roxygen2
          devtools
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
          (pkgs.rWrapper.override {
            packages = r-packages;
          })
          ];
          shellHook = ''
            echo "regexcite development environment loaded"
            echo "R version: $(R --version | head -1)"
          '';
        };
      }
    );
}
