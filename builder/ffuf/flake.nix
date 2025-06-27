{
  description = "ffuf - Fuzz Faster U Fool - A fast web fuzzer written in Go.";
  inputs.nixpkgs.url = "nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      rev = "v2.1.0";
      version = "${rev}";
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          ffuf = pkgs.buildGoModule {
            pname = "ffuf";
            inherit version;
            src = pkgs.fetchFromGitHub {
              owner = "ffuf";
              repo = "ffuf";
              rev = version;
              sha256 = "sha256-+wcNqQHtB8yCLiJXMBxolCWsYZbBAsBGS1hs7j1lzUU=";
            };
            vendorHash = "sha256-SrC6Q7RKf+gwjJbxSZkWARw+kRtkwVv1UJshc/TkNdc=";
	    doCheck = false;
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go ];
          };
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.ffuf);
    };
}
