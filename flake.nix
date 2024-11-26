{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default =
          with pkgs;
          mkShell {
            packages =
              [
                uv
                ruff
              ]
              ++ (with python3Packages; [
                uvicorn
                jedi-language-server
                python-lsp-server
              ]);
          };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
