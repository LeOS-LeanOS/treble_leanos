LOCAL_PATH := $(call my-dir)
include $(call all-subdir-makefiles,$(LOCAL_PATH))

# copy files
PRODUCT_COPY_FILES += \
    vendor/leanos/prebuiltapks/LeOS-Launcher/preferred-home.xml:system/etc/preferred-apps/preferred-activities-home.xml

# overlays
PRODUCT_PACKAGE_OVERLAYS += vendor/leanos/common/overlay

# packages
PRODUCT_PACKAGES += \
    AdvancedPrivacy \
    FakeStore \
    GmsCore \
    GsfProxy
    LatinIME \
    LeOS-Droid \
    LeOS-Icons \
    LeOS-Launcher \
    LeOS-Wallpaper \
    Sherpa

# system properties
PRODUCT_SYSTEM_PROPERTIES += \
    ro.control_privapp_permissions=enforce \
    ro.input.defaultime=org.futo.inputmethod.latin/.LatinIME \
    persist.sys.input_method=org.futo.inputmethod.latin/.LatinIME
