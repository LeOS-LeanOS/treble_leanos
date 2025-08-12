# Common ROM Configuration
# This file defines common packages and configurations shared between LeOS and LeanOS builds

LOCAL_PATH := $(call my-dir)
include $(call all-subdir-makefiles,$(LOCAL_PATH))

# common copy files
PRODUCT_COPY_FILES += \
  vendor/rom/prebuiltapks/LeOS-Launcher/preferred-home.xml:system/etc/preferred-apps/preferred-activities-home.xml

# common overlays
PRODUCT_PACKAGE_OVERLAYS += vendor/rom/common/overlay

# common packages (only packages that actually have Android.bp definitions)
PRODUCT_PACKAGES += \
	AdvancedPrivacy \
	LatinIME \
	LeOS-Droid \
	LeOS-Icons \
	LeOS-Launcher \
	LeOS-Wallpaper \
	Sherpa

# common system properties
PRODUCT_SYSTEM_PROPERTIES += \
    ro.control_privapp_permissions=enforce \
    ro.input.defaultime=org.futo.inputmethod.latin/.LatinIME \
    persist.sys.input_method=org.futo.inputmethod.latin/.LatinIME
