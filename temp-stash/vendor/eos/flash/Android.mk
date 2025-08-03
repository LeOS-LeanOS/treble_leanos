LOCAL_PATH := $(call my-dir)

IMG_PACKAGE_TARGET_CONFIG := $(LOCAL_PATH)/$(TARGET_DEVICE)/config.mk

ifneq (,$(wildcard $(IMG_PACKAGE_TARGET_CONFIG)))
IMAGE_PACKAGE_NAME := IMG-e-$(LINEAGE_VERSION)
INSTALLED_IMG_PACKAGE_TARGET := $(PRODUCT_OUT)/$(IMAGE_PACKAGE_NAME).zip
MD5 := prebuilts/build-tools/path/$(HOST_PREBUILT_TAG)/md5sum
SHA256 := prebuilts/build-tools/path/$(HOST_PREBUILT_TAG)/sha256sum
$(INSTALLED_IMG_PACKAGE_TARGET): intermediates := $(call intermediates-dir-for,PACKAGING,IMG_PACKAGE)
$(INSTALLED_IMG_PACKAGE_TARGET): zip_root := $(intermediates)/$(IMAGE_PACKAGE_NAME)

# Following variables can be defined through the config on a per device basis
HLOS_IMAGES_TARGET :=
INCLUDE_IN_IMG_PACKAGE :=
include $(IMG_PACKAGE_TARGET_CONFIG)

INSTALLED_HLOS_IMAGES_TARGET := $(addprefix $(PRODUCT_OUT)/,$(HLOS_IMAGES_TARGET))
INCLUDE_IN_IMG_PACKAGE += $(INSTALLED_HLOS_IMAGES_TARGET)

ifneq (,$(wildcard $(LOCAL_PATH)/$(TARGET_DEVICE)/flash_$(TARGET_DEVICE)_factory.sh))
INCLUDE_IN_IMG_PACKAGE += $(LOCAL_PATH)/$(TARGET_DEVICE)/flash_$(TARGET_DEVICE)_factory.sh
INCLUDE_IN_IMG_PACKAGE += $(LOCAL_PATH)/fastboot/bin-msys
INCLUDE_IN_IMG_PACKAGE += $(LOCAL_PATH)/fastboot/bin-linux-x86
endif

$(INSTALLED_IMG_PACKAGE_TARGET): $(INCLUDE_IN_IMG_PACKAGE) $(INSTALLED_RADIOIMAGE_TARGET) $(SOONG_ZIP)
	@echo "Package IMG package: $@"
	$(hide) rm -rf $@ $(zip_root)
	$(hide) mkdir -p $(zip_root)
	$(hide) $(foreach t,$(INCLUDE_IN_IMG_PACKAGE) $(INSTALLED_RADIOIMAGE_TARGET), \
                    cp -r $(t) $(zip_root)/$(notdir $(t));)
	$(hide) find $(zip_root) | sort > $(zip_root).zip.list
	$(hide) $(SOONG_ZIP) -d -o $@ -C $(zip_root) -l $(zip_root).zip.list
	$(hide) $(MD5) $@ | sed "s|$(PRODUCT_OUT)/||" > $@.md5sum
	$(hide) $(SHA256) $@ | sed "s|$(PRODUCT_OUT)/||" > $@.sha256sum

bacon: $(INSTALLED_IMG_PACKAGE_TARGET)
endif
