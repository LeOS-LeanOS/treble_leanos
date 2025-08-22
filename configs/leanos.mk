# ROM Configuration for LeanOS builds
# This file is copied to device/phh/treble/leanos.mk during the build process

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.biometrics.face.xml:system/etc/permissions/android.hardware.biometrics.face.xml

PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.face.sense_service=true
