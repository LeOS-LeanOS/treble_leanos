#$(call inherit-product-if-exists, vendor/addons/config.mk)
$(call inherit-product-if-exists, vendor/LeOS/bootanimation/android.mk)
LOCAL_PATH := $(call my-dir)
include $(call all-subdir-makefiles,$(LOCAL_PATH))

#PRODUCT_COPY_FILES += \
#    product/media/bootanimation-dark.zip:system/media/bootanimation-dark.zip

#$(call inherit-product-if-exists, vendor/extra/product.mk)

#$(call inherit-product, vendor/eos/config/common.mk)
#$(call inherit-product, vendor/LeOS/fonts/fonts.mk)

# Face Unlock
#TARGET_FACE_UNLOCK_SUPPORTED ?= $(TARGET_SUPPORTS_64_BIT_APPS)

#ifeq ($(TARGET_FACE_UNLOCK_SUPPORTED),true)
#PRODUCT_PACKAGES += \
#    ParanoidSense

#PRODUCT_SYSTEM_EXT_PROPERTIES += \
#    ro.face.sense_service=true \

#PRODUCT_COPY_FILES += \
#    frameworks/native/data/etc/android.hardware.biometrics.face.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.biometrics.face.xml
#endif

# Overlay
#PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += vendor/LeOS/overlay
#PRODUCT_PACKAGE_OVERLAYS += \
#    vendor/Leos/overlay/common

PRODUCT_SYSTEM_PROPERTIES += \
    setprop persist.sys.input_method org.futo.inputmethod.latin/.LatinIME

#prebuilts
PRODUCT_PACKAGES += \
	com.qualcomm.location \
	com.aurora.services \
	org.fdroid.fdroid.privileged \
	com.paranoid.ParanoidWallpapers \
	GmsCore \
	GsfProxy \
	FakeStore \
	com.google.android.maps.jar \
	AuroraServices \
	FDroidPrivilegedExtension \
	MozillaNlpBackend \
	NominatimNlpBackend \
	gcamphotospreview-common \
	eSpeakTTS \
	Launcher \
	com.saggitt.omega \
	omega \
	Dialer \
	Seedvault \
	FileManager \
	LeOS-Droid \
	DocumentsUI \
	Wallpaper \
	TrebleApp \
	SettingsIntelligence \
	OpenEUICC \
	Contacts \
	LineageSetupWizard \
	CalyxBlackTheme \
	GCamPhotosPreview \
	LeOS-Icons \
	com.leos.icons \
	LeOS-Phone \
	LeOS-Contacts \
	com.leos.phone \
	com.leos.contacts \
	me.phh.superuser \
	vendor.qti.qcril.am-V1.0-java \
	AdvancedPrivacy \
	elib \
                  TrebuchetQuickStep \
                  ParanoidSense \
                  PrivacyCentral \
                  privacycentralapp \
                  Sherpa \
                  picotts \
                  Futo \
                  futo \
                  org.futo.inputmethod.latin \
                  privapp-permissions-org.futo.inputmethod.latin.xml \
                  LatinIME \
                  BacklightTile \
                  Tile \
                  HideAppIcon \
                  Datura



# Bootanimation
TARGET_SCREEN_WIDTH ?= 1080
TARGET_SCREEN_HEIGHT ?= 1920
PRODUCT_PACKAGES += \
    bootanimation.zip

# Enforce privapp-permissions whitelist
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.control_privapp_permissions=enforce \
    ro.input.defaultime=org.futo.inputmethod.latin/.LatinIME \

#Launcher Default
PRODUCT_COPY_FILES += \
  vendor/LeOS/prebuiltapks/Launcher/preferred-home.xml:system/etc/preferred-apps/preferred-activities-home.xml

