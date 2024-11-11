{
  description = "Nix flake for managing homelab infrastructure with Terraform";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };
  outputs = { nixpkgs, ... }:
    let
      systems = nixpkgs.lib.platforms.all;
      eachSystem = f: nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs {
            system = system;
            config = {
              allowUnfree = true;
            };
          };
        in f pkgs
      );
    in
    {
      formatter = eachSystem (pkgs: pkgs.nixpkgs-fmt);
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            terraform
            doppler
            just
          ];
        };
      });
    };
}
