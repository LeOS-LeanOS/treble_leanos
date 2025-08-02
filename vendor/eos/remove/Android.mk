LOCAL_PATH := $(call my-dir)

HOTWORD_PACKAGES := HotwordEnrollmentOKGoogleWCD9340 HotwordEnrollmentXGoogleWCD9340 HotwordEnrollment \
        HotwordEnrollmentOKGoogleWCD9330 HotwordEnrollmentTGoogleWCD9330 HotwordEnrollmentXGoogleWCD9330 \
        HotwordEnrollmentOKGoogleHEXAGON HotwordEnrollmentXGoogleHEXAGON HotwordEnrollmentOKGoogleExCORTEXM4 \
        HotwordEnrollmentXGoogleExCORTEXM4 HotwordEnrollmentOKGoogleRT5677 HotwordEnrollmentOKGoogleWCD9335 \
        HotwordEnrollmentXGoogleWCD9335 HotwordEnrollmentOKGoogleEx2TL3210 HotwordEnrollmentXGoogleEx2TL3210 \
        HotwordEnrollmentOKGoogleWCD9340_SDM845 HotwordEnrollmentXGoogleWCD9340_SDM845 HotwordEnrollmentTGoogleWCD9335 \
        HotwordEnrollmentOKGoogleCORTEXM4 HotwordEnrollmentXGoogleCORTEXM4 HotwordEnrollmentOKGoogleEx3HEXAGON \
        HotwordEnrollmentXGoogleEx3HEXAGON HotwordEnrollmentOKGoogleWM8280 HotwordEnrollmentOKGoogleHI6403 \
        HotwordEnrollmentXGoogleHI6403 HotwordEnrollmentOKGoogleRT5514P HotwordEnrollmentXGoogleRT5514P \
        HotwordEnrollmentOKGoogleFUSIONPro HotwordEnrollmentXGoogleFUSIONPro HotwordEnrollmentOKGoogleFUSION \
        HotwordEnrollmentXGoogleFUSION HotwordEnrollmentXGoogleExWCD9340 HotwordEnrollmentOKGoogleExWCD9340 \
        HotwordEnrollmentOKGoogleRT5514 HotwordEnrollmentXGoogleRT5514 HotwordEnrollmentOKGoogleHEMIDELTA \
        HotwordEnrollmentXGoogleHEMIDELTA

DEVICE_PERSONALIZATION_PACKAGES := DevicePersonalizationPrebuiltPixel2 DevicePersonalizationPrebuiltPixel3 \
        DevicePersonalizationPrebuiltPixel4 DevicePersonalizationPrebuiltPixel2020  \
        DevicePersonalizationPrebuiltPixel2021 DevicePersonalizationPrebuiltPixel2022

include $(CLEAR_VARS)
LOCAL_MODULE := RemoveProprietaryApps
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := APPS
LOCAL_OVERRIDES_PACKAGES := DeviceIntelligenceNetworkPrebuilt AmbientSensePrebuilt \
        $(DEVICE_PERSONALIZATION_PACKAGES) $(HOTWORD_PACKAGES)
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_SRC_FILES := /dev/null
LOCAL_CERTIFICATE := PRESIGNED
include $(BUILD_PREBUILT)
