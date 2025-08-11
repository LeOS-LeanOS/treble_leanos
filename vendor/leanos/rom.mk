# LeanOS ROM-Specific Configuration
# Inherits from common base and adds LeanOS-specific packages

# Inherit common base configuration
$(call inherit-product, vendor/rom/common.mk)

# LeanOS-specific packages (microG)
PRODUCT_PACKAGES += \
    GmsCore \
    FakeStore \
    GsfProxy

# LeanOS-specific customizations can be added here
