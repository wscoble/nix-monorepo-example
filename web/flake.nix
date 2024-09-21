{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  # https://devenv.sh/reference/options/
                  starship.enable = true;

                  env = {
                    SERVER_PORT = "8080";
                  };

                  packages = with pkgs; [
                  ];

                  enterShell = ''
                    mkdir -p dist
                  '';

                  processes = {
                    tailwindcss.exec = ''
                      ${pkgs.watchexec}/bin/watchexec -w $DEVENV_ROOT/src/css -e css \
                        ${pkgs.tailwindcss}/bin/tailwindcss -c $DEVENV_ROOT/tailwind.config.js -i $DEVENV_ROOT/src/css/style.css -o $DEVENV_ROOT/dist/style.css
                    '';

                    html-watch.exec = ''
                      ${pkgs.watchexec}/bin/watchexec -w $DEVENV_ROOT/src/html -e html cp -r $DEVENV_ROOT/src/html/* $DEVENV_ROOT/dist/
                    '';
                    serve.exec = ''
                      ${pkgs.static-web-server}/bin/static-web-server -d dist
                    '';
                  };
                }
              ];
            };
          });
    };
}
