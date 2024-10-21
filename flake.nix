{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    crane,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        craneLib = (crane.mkLib nixpkgs.legacyPackages.${system});

        pkgs = import nixpkgs { inherit system; overlays = [ rust-overlay.overlays.default ]; };

        libPath =  with pkgs; lib.makeLibraryPath [
          cairo
          gdk-pixbuf
          pango
          vulkan-loader
          libGL

          wayland wayland-scanner libxkbcommon wayland-protocols

          fontconfig
          freetype
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
        ];

        nativeBuildInputs = with pkgs; [
          pkg-config
          cmake
          makeWrapper
        ];

        buildInputs = with pkgs; [
          cairo
          gdk-pixbuf
          gtk3
          pango
          expat
          pkg-config

          fontconfig
          freetype
          freetype.dev

          vulkan-headers
          vulkan-loader
          libGL

          libxkbcommon
          # WINIT_UNIX_BACKEND=wayland
          wayland

          # WINIT_UNIX_BACKEND=x11
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
        ];

        cargoArtifacts = craneLib.buildDepsOnly ({
          src = craneLib.cleanCargoSource (craneLib.path ./.);
          inherit buildInputs nativeBuildInputs;
          pname = "prayer-times-applet";
        });
      in with pkgs; {
        packages = rec {
          prayer-times-applet = craneLib.buildPackage {
            src = craneLib.path ./.;

            inherit buildInputs nativeBuildInputs cargoArtifacts;

            postInstall = ''
              for _size in 16x16 32x32 48x48 64x64 128x128 256x256; do
                  echo $src
                  install -Dm644 "$src/res/icons/hicolor/$_size/apps/com.github.BKSalman.PrayerTimesApplet.svg" "$out/share/icons/hicolor/$_size/apps/com.github.BKSalman.PrayerTimesApplet.svg"
              done
              install -Dm644 "$src/res/com.github.BKSalman.PrayerTimesApplet.desktop" -t "$out/share/applications/"
              install -Dm644 "$src/res/com.github.BKSalman.PrayerTimesApplet.metainfo.xml" -t "$out/share/metainfo/"

              wrapProgram $out/bin/prayer-times-applet --suffix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs}
            '';

            GIT_HASH = self.rev or self.dirtyRev;
          };

          default = prayer-times-applet;
        };

        devShell = mkShell {
          inherit buildInputs nativeBuildInputs;

          packages = with pkgs; [
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analyzer" ];
            })
            cargo-watch
          ];
          LD_LIBRARY_PATH = "${libPath}";
          # XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
        };
      }) // {
        overlay = final: prev: {
          inherit (self.packages.${final.system}) prayer-times-applet;
        };
      };
}
