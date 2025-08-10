# LeOS/LeanOS Base Configuration
# This file contains shared configuration for both LeOS and LeanOS variants
# Individual variants should inherit from this file and add variant-specific customizations

LOCAL_PATH := $(call my-dir)
include $(call all-subdir-makefiles,$(LOCAL_PATH))

# Common system properties
PRODUCT_SYSTEM_PROPERTIES += \
    setprop persist.sys.input_method org.futo.inputmethod.latin/.LatinIME

# Common prebuilt packages
PRODUCT_PACKAGES += \
	AdvancedPrivacy \
	AuroraServices \
	BacklightTile \
	CalyxBlackTheme \
	com.aurora.services \
	com.google.android.maps.jar \
	com.leos.contacts \
	com.leos.icons \
	com.leos.phone \
	com.paranoid.ParanoidWallpapers \
	com.qualcomm.location \
	com.saggitt.omega \
	Contacts \
	Datura \
	Dialer \
	DocumentsUI \
	elib \
	eSpeakTTS \
	FakeStore \
	FDroidPrivilegedExtension \
	FileManager \
	Futo \
	futo \
	GCamPhotosPreview \
	gcamphotospreview-common \
	GmsCore \
	GsfProxy \
	HideAppIcon \
	LatinIME \
	LeOS-Droid \
	LeOS-Icons \
	LeOS-Launcher \
	LeOS-Wallpaper \
	LineageSetupWizard \
	me.phh.superuser \
	MozillaNlpBackend \
	NominatimNlpBackend \
	omega \
	OpenEUICC \
	org.fdroid.fdroid.privileged \
	org.futo.inputmethod.latin \
	ParanoidSense \
	picotts \
	privacycentralapp \
	privapp-permissions-org.futo.inputmethod.latin.xml \
	PrivacyCentral \
	Seedvault \
	SettingsIntelligence \
	Sherpa \
	Tile \
	TrebleApp \
	TrebuchetQuickStep \
	vendor.qti.qcril.am-V1.0-java

# Common bootanimation configuration
TARGET_SCREEN_WIDTH ?= 1080
TARGET_SCREEN_HEIGHT ?= 1920
PRODUCT_PACKAGES += \
    bootanimation.zip

# Common system properties
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.control_privapp_permissions=enforce \
    ro.input.defaultime=org.futo.inputmethod.latin/.LatinIME

# Common launcher configuration
PRODUCT_COPY_FILES += \
  vendor/LeOS/prebuiltapks/LeOS-Launcher/preferred-home.xml:system/etc/preferred-apps/preferred-activities-home.xml