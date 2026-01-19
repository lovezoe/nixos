{
  description = "Hongtou's NixOS Flake Configuration";

  inputs = {
    # 使用 unstable 分支以获取最新的 mise 和 clash-verge-rev
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager 源
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # 这里的 "nixos" 必须与 networking.hostName 保持一致
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          
          # 将 Home Manager 作为 NixOS 模块导入
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.hongtou = import ./home.nix;
          }
        ];
      };
    };
  };
}
