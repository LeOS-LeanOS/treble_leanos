# leos gsi builder makefile
#
# this makefile automates the process of building leos gsi images for
# arm64 and arm32_binder64 architectures.
#
# make sure make stops if any command fails
.SHELLFLAGS := -e -c
.ONESHELL:

# variables
ARCHITECTURES := arm64 a64
BUILD_DATE := $(shell date "+%Y%m%d")
BUILD_LEANOS ?= false
BUILD_NUMBER_FILE := tmp/.build_number
BUILD_TIME := $(shell date "+%H%M%S")
CONTAINER_NAME := gsi-builder
CONTAINER_RUNTIME ?= podman
PONCES_AOSP_TAG ?= android-16.0
REPO_HOST ?= https://github.com
REPO_PATH ?= cawilliamson/treble_leos
ROM_PREFIX = $(if $(filter true,$(BUILD_LEANOS)),LeanOS,LeOS)
SEPOLICY_CHECK = if [ "$(VERIFY_SEPOLICY)" = "true" ]; then make vndk-test-sepolicy -j$$(nproc --all); fi
UPLOAD_TO_GITHUB ?= false
VERIFY_SEPOLICY ?= true

# define a function to build architecture-specific targets
define build_arch
	$(call print_section,Build $(2))
	$(CONTAINER_RUN) -w /repo/src $(CONTAINER_NAME) \
		/bin/bash -e -c ' \
			ANDROID_VERSION_TAG_VAL=$$(cat /repo/tmp/.android_version_tag) && \
			pushd device/phh/treble && \
				cp -fv "/repo/configs/rom.mk" . && \
				bash generate.sh rom && \
			popd && \
			rm -rfv out/target/product/tdgsi_$(1)_ab/ && \
			. build/envsetup.sh && \
			lunch treble_$(1)_bvN-$$ANDROID_VERSION_TAG_VAL-userdebug && \
			make systemimage -j$$(nproc --all) && \
			$(SEPOLICY_CHECK) && \
			mv -v out/target/product/tdgsi_$(1)_ab/system.img /repo/tmp/system_$(1).img'
endef

# define a function to print section headers
define print_section
	@echo ""
	@echo "#######################"
	@echo "# $(1)"
	@echo "#######################"
	@echo ""
endef

# automatically create necessary directories
$(shell mkdir -p out/ src/ tmp/)
ifeq ($(wildcard $(BUILD_NUMBER_FILE)),)
    $(shell echo "$(BUILD_DATE).$(BUILD_TIME)" > $(BUILD_NUMBER_FILE))
endif
BUILD_NUMBER := $(shell cat $(BUILD_NUMBER_FILE))

# common container parameters
CONTAINER_RUN = $(CONTAINER_RUNTIME) run --rm --privileged \
	--pids-limit=0 \
	-v "$(PWD):/repo:Z" \
	-e BUILD_DATE="$(BUILD_DATE)" \
	-e BUILD_LEANOS="$(BUILD_LEANOS)" \
	-e BUILD_NUMBER="$(BUILD_NUMBER)" \
	-e BUILD_NUMBER_FILE="$(BUILD_NUMBER_FILE)"

# phony targets
.PHONY: all build-arm32 build-arm64 build-container build-treble-app \
	clean full-build prepare-images prepare-sources sync-sources upload-to-github

# default target - runs the full build process
all: full-build

# clean all build directories to start fresh
clean:
	rm -rfv out/ src/ tmp/

# build the container image used for all build operations
build-container:
	$(CONTAINER_RUNTIME) build -t $(CONTAINER_NAME) -f Containerfile .

# full build process - simple linear chain
full-build: build-container sync-sources prepare-sources build-treble-app build-arm64 build-arm32 prepare-images
	@if [ "$(UPLOAD_TO_GITHUB)" = "true" ]; then \
		$(MAKE) upload-to-github; \
	fi

# step 1: sync sources - clone ponces repo, extract versions, init manifest, and sync
sync-sources: build-container
	$(call print_section,Sync Sources)
	$(CONTAINER_RUN) -w /repo/src $(CONTAINER_NAME) \
		/bin/bash -e -c ' \
			rm -rf ponces_aosp/ && \
			git clone --depth=1 https://github.com/ponces/treble_aosp.git -b $(PONCES_AOSP_TAG) ponces_aosp/ && \
			grep "repo init" ponces_aosp/build.sh | sed "s/.*-b \([^ ]*\).*/\1/" > /repo/tmp/.android_version && \
			grep "lunch.*-.*-userdebug" ponces_aosp/build.sh | sed "s/.*\"\$$1\"-\([^-]*\)-.*/\1/" > /repo/tmp/.android_version_tag && \
			repo init -u https://android.googlesource.com/platform/manifest -b $$(cat /repo/tmp/.android_version) --depth=1 --git-lfs && \
			mkdir -p .repo/local_manifests && \
			cp -v /repo/configs/*.xml .repo/local_manifests/ && \
			cp -v ponces_aosp/build/default.xml .repo/local_manifests/ponces_default.xml && \
			cp -v ponces_aosp/build/remove.xml .repo/local_manifests/ponces_remove.xml && \
			while ! repo sync -j$$(nproc --all) --force-sync --no-clone-bundle --no-tags; do sleep 30; done'

# step 2: prepare sources - apply patches and copy prebuilts
prepare-sources: build-container
	$(call print_section,Prepare Sources)
	$(CONTAINER_RUN) -w /repo/src $(CONTAINER_NAME) \
		/bin/bash -e -c ' \
			rm -rf patches/ && \
			cp -Rv /repo/patches . && \
			cp -Rv ponces_aosp/patches/trebledroid patches/ && \
			patches/apply.sh . trebledroid && \
			patches/apply.sh . common && \
			patches/apply.sh . leos && \
			cp -Rfv /repo/external . && \
			cp -Rfv /repo/vendor/common vendor/rom && \
			if [ "$$BUILD_LEANOS" = "true" ]; then \
				patches/apply.sh . leanos && \
				cp -Rfv /repo/vendor/leanos/* vendor/rom/; \
				pushd vendor/rom/keys && \
					./keys.sh || true && \
				popd; \
			else \
				cp -Rfv /repo/vendor/leos/* vendor/rom/; \
			fi'

# step 3: build treble app - compile the treble app
build-treble-app: build-container
	$(call print_section,Build Treble App)
	$(CONTAINER_RUN) -w /repo/src $(CONTAINER_NAME) \
		/bin/bash -e -c ' \
			if [ -d treble_app ]; then \
				cd treble_app/ && \
					bash build.sh release; \
			fi'

# step 4a: build arm64 architecture
build-arm64:
	$(call build_arch,arm64,ARM64)

# step 4b: build arm32_binder64 architecture
build-arm32:
	$(call build_arch,a64,ARM32_BINDER64)

# step 5: prepare images - rename and compress image files in one step
prepare-images: build-container
	$(call print_section,Prepare Images)
	$(CONTAINER_RUN) -w /repo/tmp $(CONTAINER_NAME) \
		/bin/bash -e -c ' \
			VERSION_TAG="$${$$(cat /repo/tmp/.android_version)#android-}-$$(cat /repo/$$BUILD_NUMBER_FILE)"; \
			for arch in $(ARCHITECTURES); do \
				src="system_$$arch.img"; \
				if [ -f "$$src" ]; then \
					dest="$(ROM_PREFIX)-$$arch-ab-$$VERSION_TAG.img"; \
					mv -v "$$src" "$$dest"; \
					xz -9 -T0 -v -z "$$dest"; \
				fi; \
			done && \
			cp -fv *.img.xz /repo/out/'

# step 6: upload images to github
upload-to-github:
	$(call print_section,Upload to GitHub)
	@cd $(PWD)/out/ && \
		git init && \
		git remote add origin "$(REPO_HOST)/$(REPO_PATH).git" && \
		RELEASE_TAG="$${$$(cat $(PWD)/tmp/.android_version)#android-}-$$(cat $(PWD)/$(BUILD_NUMBER_FILE))" && \
		gh repo set-default "$(REPO_PATH)" && \
		gh release create -d -n "" -t "$(ROM_PREFIX) $$RELEASE_TAG" "$$RELEASE_TAG" && \
		gh release upload "$$RELEASE_TAG" --clobber -- *.img.xz && \
		rm -rf .git/
