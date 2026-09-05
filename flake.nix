{
  description = "regexcite - Make Regular Expressions More Exciting";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        r-packages = with pkgs.rPackages; [
          stringr
          testthat
          roxygen2
          devtools
        ];

        fmt-packages = with pkgs; [
          air-formatter
          nixfmt
        ];

        fmt-wrapper = pkgs.writeShellApplication {
          name = "fmt";
          runtimeInputs = fmt-packages;
          text = ''
            air format "''${@:-.}"
            nixfmt flake.nix
          '';
        };

        desc = builtins.readFile ./DESCRIPTION;
        versionMatch = builtins.match ".*Version:[[:space:]]*([0-9]+\\.[0-9]+\\.[0-9]+(\\.[0-9]+)?).*" desc;
        pkgVersion = if versionMatch != null then builtins.head versionMatch else "0.0.0";

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              (rWrapper.override {
                packages = r-packages;
              })
              nil
            ]
            ++ fmt-packages;
          shellHook = ''
            echo "regexcite development environment loaded"
            echo "R version: $(R --version | head -1)"
          '';
        };

        checks = {
          format =
            pkgs.runCommand "check-format"
              {
                nativeBuildInputs = fmt-packages;
                src = ./.;
              }
              ''
                cd "$src"

                echo "Checking R formatting with air..."
                air format --check .

                echo "Checking Nix formatting with nixfmt..."
                nixfmt --check flake.nix

                touch $out
              '';

          r-cmd-check = pkgs.rPackages.buildRPackage {
            pname = "regexcite";
            version = pkgVersion;
            src = ./.;
            propagatedBuildInputs = r-packages;

            doCheck = true;

            checkPhase = ''
              runHook preCheck
              export _R_CHECK_CRAN_INCOMING_=false
              export _R_CHECK_CRAN_INCOMING_REMOTE_=false
              export _R_CHECK_FORCE_SUGGESTS_=false
              R CMD build .
              R CMD check regexcite_*.tar.gz --no-manual --as-cran
              runHook postCheck
            '';
          };
        };

        formatter = fmt-wrapper;
      }
    );
}
