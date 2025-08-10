# LeOS Variant Configuration
# Inherits from common base configuration and adds LeOS-specific customizations

# Inherit from common base configuration
$(call inherit-product, vendor/common/base.mk)

# LeOS-specific bootanimation
$(call inherit-product-if-exists, vendor/rom/bootanimation/android.mk)

# LeOS-specific customizations can be added here
# Currently, LeOS uses the standard base configuration without modifications
