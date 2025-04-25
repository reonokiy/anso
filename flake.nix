{
  description = "anso";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    deploy-rs.url = "github:serokell/deploy-rs";
    disko.url = "github:nix-community/disko";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/reonokiy/anso-secrets.git?ref=main";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      deploy-rs,
      disko,
      sops-nix,
      nixos-anywhere,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          devShells.default = pkgs.mkShell {
            name = "default";
            packages = [
              pkgs.just
              pkgs.python3
              pkgs.openssh
              pkgs.nil
              pkgs.nixfmt-rfc-style
              pkgs.wireguard-tools
              nixos-anywhere.packages.${system}.default
              deploy-rs.packages.${system}.default
            ];
          };
        };

      flake = {
        nixosConfigurations.aios = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs =
            let
              machine = import (inputs.secrets + "/aios.nix");
            in
            {
              inherit inputs machine;
            };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/aios
          ];
        };
        nixosConfigurations.buno = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs =
            let
              machine = import (inputs.secrets + "/buno.nix");
            in
            {
              inherit inputs machine;
            };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/buno
          ];
        };
        # nixosConfigurations.deco = nixpkgs.lib.nixosSystem {
        #   system = "aarch64-linux";
        #   specialArgs =
        #     let
        #       machine = import (inputs.secrets + "/deco.nix");
        #     in
        #     {
        #       inherit inputs machine;
        #     };
        #   modules = [
        #     disko.nixosModules.disko
        #     sops-nix.nixosModules.sops
        #     ./hosts/deco
        #   ];
        # };

        deploy.nodes.aios = {
          hostname = "100.100.10.1";
          profiles.system = {
            user = "root";
            sshUser = "root";
            autoRollback = false;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.aios;
          };
        };
        deploy.nodes.buno = {
          hostname = "100.100.10.2";
          profiles.system = {
            user = "root";
            sshUser = "root";
            autoRollback = false;
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.buno;
          };
        };
        # deploy.nodes.deco = {
        #   hostname = "deco";
        #   profiles.system = {
        #     user = "root";
        #     sshUser = "root";
        #     autoRollback = false;
        #     path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.buno;
        #   };
        # };

        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };
    };
}
