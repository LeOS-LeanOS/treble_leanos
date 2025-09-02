{ config, pkgs, lib, ... }:

{
  # Basic device configuration
  device = "generic";
  flavor = "vanilla"; # We'll customize this heavily

  # Android version - will be determined dynamically from ponces build
  androidVersion = 14; # Update this based on your target version

  # Build configuration
  buildNumber = builtins.toString (builtins.currentTime / 1000000); # Unix timestamp in seconds
  buildDateTime = builtins.toString builtins.currentTime;

  # Source configuration
  source = {
    # We'll use the standard AOSP manifest but add our custom manifests
    manifest = {
      url = "https://android.googlesource.com/platform/manifest";
      # This will be dynamically set based on ponces build info
      rev = "refs/heads/android-14.0.0_r50"; # Example, update as needed
    };

    # Additional repositories for treble and custom components
    additionalRepos = {
      "treble_app" = {
        url = "https://github.com/phhusson/treble_app";
        rev = "android-14.0";
        path = "treble_app";
      };
      "vendor/hardware/overlay" = {
        url = "https://github.com/phhusson/vendor_hardware_overlay";
        rev = "android-14.0";
        path = "vendor/hardware/overlay";
      };
      "device/phh/treble" = {
        url = "https://github.com/phhusson/device_phh_treble";
        rev = "android-14.0";
        path = "device/phh/treble";
      };
    };
  };

  # Custom patches and source directories
  source.dirs = {
    # Copy our external components
    "external/chromium-webview" = ./external/chromium-webview;
    "vendor/leanos" = ./vendor;
  };

  # Build targets
  productNamePrefix = "treble";

  # Custom build configuration
  envVars = {
    BUILD_NUMBER = config.buildNumber;
    BUILD_DATETIME = config.buildDateTime;
  };

  # Signing configuration
  signing = {
    enable = true;
    keyStorePath = "/home/chrisaw/.android-certs";
  };

  # Build multiple architectures
  variants = {
    arm64 = {
      arch = "arm64";
      productName = "treble_arm64_bvN";
    };
    arm32 = {
      arch = "arm";
      productName = "treble_a64_bvN";
    };
  };

  # Output configuration
  buildTargets = [ "systemimage" "target-files-package" "otatools" ];
}
