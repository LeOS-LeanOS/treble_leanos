# LeOS ROM-Specific Configuration
# Inherits from common base and adds LeOS-specific packages

# Inherit common base configuration
$(call inherit-product, vendor/rom/common.mk)

# LeOS-specific packages (microG)
PRODUCT_PACKAGES += \
    GmsCore \
    FakeStore \
    GsfProxy

# LeOS-specific customizations can be added here
