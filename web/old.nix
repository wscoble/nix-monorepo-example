{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      
      files = pkgs.stdenv.mkDerivation {
        name = "web files";
        src = ./.;
        buildPhase = ''
          mkdir -p $out
          echo "<html><body>Hello World!</body></html>" >> $out/index.html
        '';
      };

      container = pkgs.dockerTools.buildImage {
        name = "web";
        contents = [ pkgs.static-web-server files ];
        config = {
          Cmd = [
            "${pkgs.static-web-server}/bin/static-web-server"
            "-d" "${files}"
            "--health=true"
          ];
          ExposedPorts = {
            "80/tcp" = {};
          };
        };
      };
    in
    {
      packages.files = files;
      packages.container = container;
    }
  );
}
