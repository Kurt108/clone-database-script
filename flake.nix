{
  description = "Nix development environment for the clone-database-script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        scriptName = "clone-database-script";
        scriptSrc = ./src/clone-database-script.sh;
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = scriptName;
          version = "1.0.0";
          src = scriptSrc;
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/${scriptName}
            chmod +x $out/bin/${scriptName}
          '';
          postFixup = ''
            wrapProgram $out/bin/${scriptName} \
              --set PATH ${pkgs.lib.makeBinPath [ pkgs.bash pkgs.kubectl pkgs.docker pkgs.netcat pkgs.gum ]}
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bash
            pkgs.kubectl
            pkgs.docker
            pkgs.netcat
            pkgs.gum
          ];
          shellHook = ''
            echo "Nix development environment for the clone-database-script is ready."
          '';
        };
      }
    );
}
