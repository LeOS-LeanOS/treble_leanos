# Copyright (C) 2022 E FOUNDATION
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

VENDOR_PATH := vendor/eos

PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += \
    system/%

# /e/ OS packages
PRODUCT_PACKAGES += \
    GmsCore \
    GsfProxy \
    FakeStore \
    Mail \
    BlissLauncher3 \
    BlissWeather \
    AccountManager \
    Camera \
    eDrive \
    Notes \
    Tasks \
    DroidGuard \
    OpenKeychain \
    Message \
    Browser \
    BrowserWebView \
    Apps \
    PwaPlayer \
    AdvancedPrivacy \
    SplitInstallService \
    WebCalendarManager \
    Talkback \
    mapsOverlay \
    eCalendar \
    Ntfy \
    MurenaMDM

# Removes proprietary apps
PRODUCT_PACKAGES += \
    RemoveProprietaryApps

# Parental
PRODUCT_PACKAGES += ParentalControl

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += vendor/eos/sepolicy

# PicoTTS
ifneq ($(TARGET_SUPPORTS_32_BIT_APPS),false)
include $(call inherit-product, external/svox/svox_tts.mk)
endif

# Optional applications
MINIMAL_APPS ?= false

ifeq ($(MINIMAL_APPS),false)
PRODUCT_PACKAGES += \
    MagicEarth \
    PdfViewer

endif

# CustomLocale
ifeq (test,$(RELEASE_TYPE))
PRODUCT_PACKAGES += \
    CustomLocale
endif

# Overlays
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += $(VENDOR_PATH)/overlay/no-rro

DEVICE_PACKAGE_OVERLAYS += \
    $(VENDOR_PATH)/overlay/common \
    $(VENDOR_PATH)/overlay/no-rro

# Permissions
PRODUCT_COPY_FILES += \
    $(VENDOR_PATH)/config/permissions/org.lineageos.weather.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/org.lineageos.weather.xml

# Pre-granted eos-permissions and allowlist
PRODUCT_COPY_FILES += \
    $(VENDOR_PATH)/config/permissions/eos-permissions.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/default-permissions/eos-permissions.xml \
    $(VENDOR_PATH)/config/permissions/eos-allowlist.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/sysconfig/eos-allowlist.xml

# SafetyNet compatibility
ifneq ($(filter official community partner,$(RELEASE_TYPE)),)
  # Ship ih8sn on community & official builds
  INCLUDE_IH8SN ?= true
endif

INCLUDE_IH8SN ?= false

PRODUCT_CONFIGURATION_FILE := vendor/eos/config/ih8sn/ih8sn_$(subst lineage_,,$(TARGET_PRODUCT)).conf
DEFAULT_CONFIGURATION_FILE := vendor/eos/config/ih8sn/ih8sn_default.conf
ifeq (true,$(INCLUDE_IH8SN))
  PRODUCT_PACKAGES += ih8sn
  ifneq (,$(wildcard $(PRODUCT_CONFIGURATION_FILE)))
    PRODUCT_COPY_FILES += \
        $(PRODUCT_CONFIGURATION_FILE):$(TARGET_COPY_OUT_SYSTEM)/etc/ih8sn.conf
  else
    PRODUCT_COPY_FILES += \
        $(DEFAULT_CONFIGURATION_FILE):$(TARGET_COPY_OUT_SYSTEM)/etc/ih8sn.conf
  endif
endif
