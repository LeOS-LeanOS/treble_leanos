# LeanOS Variant Configuration
# Inherits from common base configuration and adds LeanOS-specific customizations

# Inherit from common base configuration
$(call inherit-product, vendor/common/base.mk)

# LeanOS-specific bootanimation (still uses rom bootanimation)
$(call inherit-product-if-exists, vendor/rom/bootanimation/android.mk)

# LeanOS-specific customizations can be added here
# Currently, LeanOS uses the standard base configuration without modifications
