{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs = { nixpkgs.follows = "nixpkgs"; };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, devenv, systems, fenix, ... } @ inputs:
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
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  # https://devenv.sh/reference/options/
                  packages = [
                    pkgs.libGL
                    pkgs.libGLU
                    pkgs.xorg.libX11
                    pkgs.xorg.libXcursor
                    pkgs.xorg.libXrandr
                    pkgs.xorg.libXi
                    pkgs.libxkbcommon
                    pkgs.vulkan-loader
                    pkgs-unstable.mesa
                    pkgs-unstable.mesa.drivers

                    pkgs-unstable.alsa-lib.dev
                    pkgs-unstable.libudev-zero
                  ];

                  languages.rust.enable = true;
                  languages.rust.channel = "nightly";
                  languages.rust.toolchain.cargo = pkgs-unstable.cargo;
                  languages.rust.toolchain.clippy = pkgs-unstable.clippy;
                  languages.rust.toolchain.rustc = pkgs-unstable.rustc;
                  languages.rust.toolchain.rust-analyzer = pkgs-unstable.rust-analyzer;

                  enterShell = ''
                    cargo --version
                    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [
                      pkgs.libGL
                      pkgs.libGLU
                      pkgs.xorg.libX11
                      pkgs.xorg.libXcursor
                      pkgs.xorg.libXrandr
                      pkgs.xorg.libXi
                      pkgs.libxkbcommon
                      pkgs.vulkan-loader
                      pkgs-unstable.mesa
                      pkgs-unstable.mesa.drivers
                    ]}"
                    export LIBGL_DRIVERS_PATH=${pkgs-unstable.mesa.drivers}/lib/dri
                    export __GLX_VENDOR_LIBRARY_NAME=mesa
                  '';

                  processes.hello.exec = "hello";
                }
              ];
            };
          });
    };
}
