# LeanOS ROM Configuration
# This file defines the packages and configurations for LeanOS builds

LOCAL_PATH := $(call my-dir)
include $(call all-subdir-makefiles,$(LOCAL_PATH))

# Include common vendor configuration
$(call inherit-product, vendor/rom/common.mk)

# LeanOS-specific packages
PRODUCT_PACKAGES += \
    bootanimation.zip \
    FakeStore \
    GmsCore \
    GsfProxy
