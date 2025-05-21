{ 
  pkgs ? import <nixpkgs> {}:
  let
    bashScript = pkgs.writeShellScriptBin "clone-database-script" ''
      #!${pkgs.bash}/bin/bash
      ${pkgs.fetchFromGitHub {
        owner = "kurt108"; # replace with your GitHub username
        repo = ""clone-database-script"; # replace with your repository name
        rev = "main"; # replace with the desired branch or commit
        src = "src/clone-database-script.sh";
      }}
    '';
  in
  {
    inherit bashScript;
  }
}
