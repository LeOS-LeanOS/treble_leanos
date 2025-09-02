# LeanOS with Nix Robotnix

This project has been migrated from a justfile/podman setup to use Nix Robotnix for building Android ROMs on NixOS.

## Prerequisites

- NixOS or Nix with flakes enabled
- Git
- Sufficient disk space (100GB+ recommended)

## Quick Start

### Enter Development Environment

```bash
nix develop
```

### Build Commands

```bash
# Build ARM64 variant
nix build .#arm64

# Build ARM32 variant  
nix build .#arm32

# Build both variants
nix build .#default
```

## What's Included

The Nix Robotnix configuration automatically handles:

- **AOSP Source Management**: Fetches the correct Android version from ponces/treble_aosp
- **Manifest Setup**: Applies both ponces and LeanOS custom manifests
- **Patch Application**: Applies patches in the correct order:
  1. trebledroid patches
  2. staging patches
  3. ponces staging patches (if available)
  4. LeanOS patches
- **Custom Components**: Includes chromium-webview and vendor/leanos
- **TrebleApp Build**: Builds the treble app as part of the process
- **Device Configuration**: Sets up LeanOS-specific device config
- **Signing**: Uses your existing Android certificates from `~/.android-certs`

## Build Outputs

Built images will be available in the Nix store and can be found in `result/` symlinks after building.

## Migration from justfile

The new Nix setup replaces your previous justfile workflow:

| Old Command | New Command |
|-------------|-------------|
| `just build-all` | `nix build .#default` |
| `just build-arm64` | `nix build .#arm64` |
| `just build-arm32` | `nix build .#arm32` |
| `just clean` | Not needed (Nix handles this) |

## Advantages of Nix Robotnix

- **Reproducible Builds**: Same inputs always produce the same outputs
- **No Container Overhead**: Builds directly on your NixOS system
- **Dependency Management**: All build dependencies are declaratively managed
- **Caching**: Nix can cache and reuse build artifacts
- **Parallel Builds**: Better resource utilization
- **Cleaner Environment**: No need to manage container images

## Configuration

The main configuration is in [`flake.nix`](flake.nix). Key settings:

- **Android Version**: Currently set to Android 14
- **Build Targets**: ARM64 and ARM32 variants
- **Signing**: Uses certificates from `~/.android-certs`
- **Custom Patches**: Applied from `patches/` directory

## Troubleshooting

### Build Fails
- Ensure you have enough disk space
- Check that `~/.android-certs` exists and contains your signing keys
- Verify all patches apply cleanly

### Flake Issues
- Run `nix flake check` to validate the configuration
- Use `nix develop` to enter the development environment for debugging

### Performance
- Use `--max-jobs` to control parallel builds: `nix build --max-jobs 8 .#arm64`
- Consider using `--cores` to limit CPU cores per job
