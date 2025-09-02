{
  description = "LeanOS Android ROM build using Robotnix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    robotnix = {
      url = "github:danielfullmer/robotnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, robotnix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Common configuration for LeanOS builds
      commonConfig = {
        device = "generic";
        flavor = "vanilla";
        androidVersion = 14;

        # Build configuration
        buildNumber = builtins.toString (builtins.currentTime / 1000000);
        buildDateTime = builtins.toString builtins.currentTime;

        # Source configuration
        source = {
          manifest = {
            url = "https://android.googlesource.com/platform/manifest";
            rev = "refs/heads/android-14.0.0_r50";
          };

          # Include our custom directories
          dirs = {
            "external/chromium-webview" = ./external/chromium-webview;
            "vendor/leanos" = ./vendor;
          };

          # Custom repos for treble
          repos = {
            "treble_app" = {
              url = "https://github.com/phhusson/treble_app";
              rev = "android-14.0";
            };
            "device/phh/treble" = {
              url = "https://github.com/phhusson/device_phh_treble";
              rev = "android-14.0";
            };
            "vendor/hardware/overlay" = {
              url = "https://github.com/phhusson/vendor_hardware_overlay";
              rev = "android-14.0";
            };
          };
        };

        # Signing configuration
        signing = {
          enable = true;
          keyStorePath = "/home/chrisaw/.android-certs";
        };

        # Build targets
        buildTargets = [ "systemimage" "target-files-package" "otatools" ];

        # Custom build phases
        source.buildPhases = {
          # Setup manifests and fetch ponces info
          preBuild = ''
            echo "Setting up LeanOS build..."

            # Fetch ponces build info
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            ${pkgs.git}/bin/git clone --depth=1 https://github.com/ponces/treble_aosp.git

            # Copy ponces manifests
            mkdir -p $ANDROID_BUILD_TOP/.repo/local_manifests
            cp treble_aosp/build/default.xml $ANDROID_BUILD_TOP/.repo/local_manifests/ponces_default.xml
            cp treble_aosp/build/remove.xml $ANDROID_BUILD_TOP/.repo/local_manifests/ponces_remove.xml

            # Copy our manifests
            cp ${./configs}/*.xml $ANDROID_BUILD_TOP/.repo/local_manifests/

            # Setup patches
            mkdir -p $ANDROID_BUILD_TOP/patches
            cp -r treble_aosp/patches/trebledroid $ANDROID_BUILD_TOP/patches/
            [ -d treble_aosp/patches/staging ] && cp -r treble_aosp/patches/staging $ANDROID_BUILD_TOP/patches/ponces_staging
            cp -r ${./patches}/* $ANDROID_BUILD_TOP/patches/

            rm -rf "$TEMP_DIR"
          '';

          # Apply patches
          postPatch = ''
            cd $ANDROID_BUILD_TOP

            # Apply patches in order
            [ -d patches/trebledroid ] && patches/apply.sh . trebledroid
            [ -d patches/staging ] && patches/apply.sh . staging
            [ -d patches/ponces_staging ] && patches/apply.sh . ponces_staging
            [ -d patches/leanos ] && patches/apply.sh . leanos
          '';

          # Build treble app
          preBuildProduct = ''
            cd $ANDROID_BUILD_TOP/treble_app
            bash build.sh release
          '';

          # Setup device config
          preProductConfig = ''
            cd $ANDROID_BUILD_TOP/device/phh/treble
            cp ${./configs/leanos.mk} .
            bash generate.sh leanos
          '';
        };
      };

    in {
      # Development shell
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git git-lfs curl wget unzip xz
          gnumake gcc python3 openjdk11
          nixpkgs-fmt
        ];

        shellHook = ''
          echo "LeanOS Robotnix Development Environment"
          echo "Build commands:"
          echo "  nix build .#arm64    - Build ARM64 variant"
          echo "  nix build .#arm32    - Build ARM32 variant"
        '';
      };

      # Build packages
      packages.${system} = {
        # ARM64 build
        arm64 = (robotnix.lib.robotnixSystem {
          inherit system;
          configuration = { config, pkgs, lib, ... }: commonConfig // {
            productName = "treble_arm64_bvN";
          };
        }).img;

        # ARM32 build
        arm32 = (robotnix.lib.robotnixSystem {
          inherit system;
          configuration = { config, pkgs, lib, ... }: commonConfig // {
            productName = "treble_a64_bvN";
          };
        }).img;

        # Default to ARM64
        default = self.packages.${system}.arm64;
      };
    };
}
