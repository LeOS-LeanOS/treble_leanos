# Vendor Configuration Structure

This directory contains the vendor-specific configurations for LeOS and LeanOS ROM variants.

## Structure

```
vendor/
├── common/
│   └── base.mk          # Shared base configuration for all variants
├── LeOS/
│   └── leos.mk          # LeOS-specific configuration (inherits from base)
└── LeanOS/
    └── leos.mk          # LeanOS-specific configuration (inherits from base)
```

## Configuration Inheritance

Both LeOS and LeanOS variants inherit from the common base configuration:

- **`vendor/common/base.mk`**: Contains all shared packages, properties, and configurations
- **`vendor/LeOS/leos.mk`**: LeOS-specific customizations (currently none)
- **`vendor/LeanOS/leos.mk`**: LeanOS-specific customizations (currently none)

## Benefits of This Structure

1. **DRY Principle**: Eliminates duplicate configuration code
2. **Maintainability**: Single source of truth for common packages
3. **Consistency**: Ensures both variants stay in sync
4. **Extensibility**: Easy to add variant-specific customizations

## Adding Variant-Specific Customizations

To add customizations specific to a variant, edit the respective `leos.mk` file:

### For LeOS-specific packages:
```makefile
# In vendor/LeOS/leos.mk
PRODUCT_PACKAGES += \
    LeOS-SpecificApp
```

### For LeanOS-specific packages:
```makefile
# In vendor/LeanOS/leos.mk
PRODUCT_PACKAGES += \
    LeanOS-SpecificApp
```

## Build Process Integration

The build system automatically handles the inheritance structure:

1. **During `copy-prebuilts`**: The entire `vendor/` directory is copied to `src/vendor/`
2. **Variant selection**: Based on the `BUILD_LEANOS` flag, the appropriate variant's `leos.mk` is copied to `src/vendor/LeOS/leos.mk`
3. **Inheritance resolution**: The Android build system resolves the `$(call inherit-product, vendor/common/base.mk)` directive

## Migration Notes

This structure was created to consolidate the previously identical LeOS and LeanOS configurations, reducing code duplication from 154 lines to 103 lines total (81 lines in base + 11 lines per variant).

The Makefile's `copy-prebuilts` step was updated to preserve the inheritance structure instead of flattening the vendor directories.