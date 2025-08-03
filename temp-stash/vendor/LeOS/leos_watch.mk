#$(call inherit-product, vendor/addons/config.mk)
#LOCAL_PATH := $(call my-dir)
#include $(call all-subdir-makefiles,$(LOCAL_PATH))

#$(call inherit-product, vendor/lineage/config/common_mobile.mk)
#-include vendor/eos/config/common.mk
#-include vendor/eos/config/telephony.mk

#prebuilts
PRODUCT_PACKAGES += \
	me.phh.superuser \
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
	Contacts \
	CalyxBlackTheme \
	GCamPhotosPreview \
	LeOS-Icons \
	com.leos.icons \
	LeOS-Phone \
	LeOS-Contacts \
	com.leos.phone \
	com.leos.contacts \
	us.spotco.mulch_wv \
	mulch \
	Mulch \


#### aptX files  LeOS Changes
PRODUCT_COPY_FILES += \
	vendor/LeOS/libaptX_encoder.so:system/lib64/libaptX_encoder.so \
	vendor/LeOS/libaptXHD_encoder.so:system/lib64/libaptXHD_encoder.so \
	vendor/LeOS/libaptX_encoder32.so:system/lib/libaptX_encoder.so \
	vendor/LeOS/libaptXHD_encoder32.so:system/lib/libaptXHD_encoder.so \
        vendor/LeOS/libperipheral_client.so:system/lib64/libperipheral_client.so \

### webview files
PRODUCT_COPY_FILES += \
	vendor/LeOS/libmonochrome_64.so:system/lib64/libmonochrome_64.so \
	vendor/LeOS/libcrashpad_handler_trampoline.so:system/lib64/libcrashpad_handler_trampoline.so \
	vendor/LeOS/libarcore_sdk_c.so:system/lib64/libarcore_sdk_c.so \
	vendor/LeOS/libdummy.so:system/lib64/libdummy.so \
	vendor/LeOS/libdummy.so:system/lib/libdummy.so \
	vendor/LeOS/libarcore_sdk_c.so:system/lib/libarcore_sdk_c.so \

# Themes
PRODUCT_PACKAGES += \
    LineageBlackTheme \

PRODUCT_PROPERTY_OVERRIDES += \
	AndroidBlackThemeOverlay=true \
	org.lineageos.overlay.customization.blacktheme=true \
	com.android.system.theme.black=true

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
	Settings.Secure.UI_NIGHT_MODE=2
