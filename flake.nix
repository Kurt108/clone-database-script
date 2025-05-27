{
  description = "Nix Flake für clone-database-script.sh";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        scriptName = "clone-database-script";
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = scriptName;
          version = "1.1.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper pkgs.coreutils ];
          installPhase = ''
            mkdir -p $out/bin
            cp src/clone-database-script.sh $out/bin/${scriptName}
            chmod +x $out/bin/${scriptName}
          '';
          postFixup = ''
            wrapProgram $out/bin/${scriptName} \
              --set PATH ${pkgs.lib.makeBinPath [ pkgs.bash pkgs.kubectl pkgs.kubectx pkgs.docker pkgs.netcat pkgs.gum ]}
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bash
            pkgs.kubectl
            pkgs.kubectx
            pkgs.docker
            pkgs.netcat
            pkgs.gum
            pkgs.grep
          ];
          shellHook = ''
            echo "Nix development environment for the clone-database-script is ready."
          '';
        };
      }
    );
}
