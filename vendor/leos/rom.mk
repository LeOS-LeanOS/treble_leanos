# LeOS ROM Configuration
# This file defines the packages and configurations for LeOS builds

# Include common vendor configuration
$(call inherit-product, vendor/rom/common.mk)

# LeOS specific packages
PRODUCT_PACKAGES += \
    GmsCore \
    FakeStore \
    GsfProxy \
    AdvancedPrivacy \
    LatinIME \
    LeOS-Droid \
    LeOS-Icons \
    LeOS-Launcher \
    LeOS-Wallpaper \
    Sherpa
