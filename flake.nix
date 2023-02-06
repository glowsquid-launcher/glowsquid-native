{
  description = "Build a cargo project with a custom toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };

      custom-rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = ["rust-src" "rust-analyzer"];
      };

      craneLib = (crane.mkLib pkgs).overrideToolchain custom-rust;

      my-crate = craneLib.buildPackage {
        src = craneLib.cleanCargoSource ./.;

        nativeBuildInputs = with pkgs; [
          appstream-glib
          git
          meson
          ninja
          pkg-config
          wrapGAppsHook4
        ];

        buildInputs = with pkgs;
          [
            gdk-pixbuf
            glib
            gnome.adwaita-icon-theme
            gtk4
            gtksourceview5
            libadwaita
            openssl
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
          ];
      };
    in {
      checks = {
        inherit my-crate;
      };

      packages.default = my-crate;

      apps.default = flake-utils.lib.mkApp {
        drv = my-crate;
      };

      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.attrValues self.checks;

        nativeBuildInputs = with pkgs; [
          appstream-glib
          git
          meson
          ninja
          pkg-config
          wrapGAppsHook4
        ];

        buildInputs = with pkgs;
          [
            gdk-pixbuf
            glib
            gnome.adwaita-icon-theme
            gtk4
            gtksourceview5
            libadwaita
            openssl
            custom-rust
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
          ];
      };
    });
}
