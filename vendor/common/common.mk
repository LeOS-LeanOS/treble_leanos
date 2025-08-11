# Common ROM Configuration
# This file defines common packages and configurations shared between LeOS and LeanOS builds

# common overlays
PRODUCT_PACKAGE_OVERLAYS += vendor/rom/common/overlay

# common packages
PRODUCT_PACKAGES += \
    AdvancedPrivacy \
    FakeStore \
    GmsCore \
    GsfProxy \
    LatinIME \
    LeOS-Droid \
    LeOS-Icons \
    LeOS-Launcher \
    LeOS-Wallpaper \
    Sherpa
