{
  description = "Dotfiles: nix-managed packages via Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs = { self, nixpkgs, home-manager, ghostty }: let
    supportedSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];

    pkgsFor = system: import nixpkgs { inherit system; };

    packageList = system: let
      pkgs = pkgsFor system;
      base = with pkgs; [
        chezmoi
        git
        tree
        zsh
        awscli2
        zsh-autosuggestions
        zsh-syntax-highlighting
        diskonaut
      ];
      ghosttyPkgs = if isLinux system then [ ghostty.packages.${system}.default ] else [];
      linuxExtras = with pkgs; [
        gcc
        unzip
        fontconfig
      ];
    in base ++ ghosttyPkgs ++ (if isLinux system then linuxExtras else []);

    homeModuleFor = system: { pkgs, ... }: {
      home.stateVersion = "24.11";
      home.packages = packageList system;

      programs.zsh = {
        enable = true;
        initExtra = ''
          # Source chezmoi-managed zsh config
          [[ -f "$HOME/.zsh/chezmoi.zshrc" ]] && source "$HOME/.zsh/chezmoi.zshrc"
        '';
      };
    };

    homeConfigFor = system: home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor system;
      modules = [
        (homeModuleFor system)
        {
          home.username = "oda_yuya";
          home.homeDirectory =
            if isLinux system then "/home/oda_yuya"
            else "/Users/oda_yuya";
        }
      ];
    };

    forAllSystems = f: builtins.listToAttrs (map (s: { name = s; value = f s; }) supportedSystems);

  in {
    packages = forAllSystems (system: (pkgsFor system).buildEnv {
      name = "dotfiles-packages";
      paths = packageList system;
    });

    devShells = forAllSystems (system: (pkgsFor system).mkShell {
      buildInputs = packageList system;
    });

    homeConfigurations = forAllSystems homeConfigFor;
  };
}
