# leos gsi builder makefile
#
# this makefile automates the process of building leos gsi images for
# arm64 and arm32_binder64 architectures.
#
# make sure make stops if any command fails
.SHELLFLAGS := -e -c
.ONESHELL:

# define a function to build architecture-specific targets
define build_arch
	$(call print_section,Build $(2))
	$(CONTAINER_RUN) -w /repo/src \
		/bin/bash -e -c ' \
			ANDROID_VERSION_TAG_VAL=$$(cat /repo/$(ANDROID_VERSION_TAG_FILE)) && \
			cd device/phh/treble && \
				cp -fv "/repo/configs/leos.mk" leos.mk && bash generate.sh leos && \
			cd /repo/src && \
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

# variables
ANDROID_VERSION_FILE := tmp/.android_version
ANDROID_VERSION_TAG_FILE := tmp/.android_version_tag
APPLY_PONCES_STAGING_PATCHES ?= true
ARCHITECTURES := arm64 a64
ARCH_DISPLAY_NAMES := arm64 arm32_binder64
BUILD_DATE := $(shell date "+%Y%m%d")
BUILD_LEANOS ?= false
BUILD_NUMBER_FILE := tmp/.build_number
BUILD_TIME := $(shell date "+%H%M%S")
CONTAINER_RUNTIME ?= podman
PONCES_AOSP_TAG ?= android-16.0
REPO_HOST ?= https://github.com
REPO_PATH ?= cawilliamson/treble_leos
ROM_PREFIX = $(if $(filter true,$(BUILD_LEANOS)),LeanOS,LeOS)
SEPOLICY_CHECK = if [ "$(VERIFY_SEPOLICY)" = "true" ]; then make vndk-test-sepolicy -j$$(nproc --all); fi
UPLOAD_TO_GITHUB ?= false
VERIFY_SEPOLICY ?= true

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
	-e ANDROID_VERSION_FILE="$(ANDROID_VERSION_FILE)" \
	-e ANDROID_VERSION_TAG_FILE="$(ANDROID_VERSION_TAG_FILE)" \
	-e BUILD_LEANOS="$(BUILD_LEANOS)" \
	-e BUILD_DATE="$(BUILD_DATE)" \
	-e BUILD_NUMBER="$(BUILD_NUMBER)" \
	-e BUILD_NUMBER_FILE="$(BUILD_NUMBER_FILE)" \
	gsi-builder

# phony targets
.PHONY: all apply-patches build-arm32 build-arm64 build-container build-treble-app \
	clean copy-prebuilts full-build prepare-images sync-sources upload-to-github

# default target - runs the full build process
all: full-build

# clean all build directories to start fresh
clean:
	rm -rfv out/ src/ tmp/

# build the container image used for all build operations
build-container:
	$(CONTAINER_RUNTIME) build -t leos-gsi-builder -f Containerfile .

# full build process - simple linear chain
full-build: build-container sync-sources apply-patches copy-prebuilts build-treble-app build-arm64 build-arm32 prepare-images
	@if [ "$(UPLOAD_TO_GITHUB)" = "true" ]; then \
		$(MAKE) upload-to-github; \
	fi

# build steps

# step 1: sync sources - clone ponces repo, extract versions, init manifest, and sync
sync-sources: build-container
	$(call print_section,Sync Sources)
	$(CONTAINER_RUN) -w /repo/src \
		/bin/bash -e -c ' \
			rm -rf ponces_aosp/ && \
			git clone --depth=1 https://github.com/ponces/treble_aosp.git -b $(PONCES_AOSP_TAG) ponces_aosp/ && \
			grep "repo init" ponces_aosp/build.sh | sed "s/.*-b \([^ ]*\).*/\1/" > /repo/$(ANDROID_VERSION_FILE) && \
			grep "lunch.*-.*-userdebug" ponces_aosp/build.sh | sed "s/.*\"\$$1\"-\([^-]*\)-.*/\1/" > /repo/$(ANDROID_VERSION_TAG_FILE) && \
			repo init -u https://android.googlesource.com/platform/manifest -b $$(cat /repo/$(ANDROID_VERSION_FILE)) --depth=1 --git-lfs && \
			mkdir -p .repo/local_manifests && \
			cp -v /repo/configs/*.xml .repo/local_manifests/ && \
			cp -v ponces_aosp/build/default.xml .repo/local_manifests/ponces_default.xml && \
			cp -v ponces_aosp/build/remove.xml .repo/local_manifests/ponces_remove.xml && \
			until repo sync -j$$(nproc --all) --force-sync --no-clone-bundle --no-tags; do \
				echo "Sync failed, retrying in 30 seconds..."; sleep 30; \
			done'

# step 2: apply patches - apply leos patches to the source
apply-patches: build-container
	$(call print_section,Apply Patches)
	$(CONTAINER_RUN) -w /repo/src \
		/bin/bash -e -c ' \
			rm -rf patches/ && \
			cp -Rv /repo/patches . && \
			cp -Rv ponces_aosp/patches/trebledroid patches/ && \
			patches/apply.sh . trebledroid && \
			patches/apply.sh . common && \
            if [ "$$APPLY_PONCES_STAGING_PATCHES" = "true" ] && [ -d "ponces_aosp/patches/staging" ]; then \
				cp -Rv ponces_aosp/patches/staging patches/ponces_staging && \
				patches/apply.sh . ponces_staging; \
			fi && \
			patches/apply.sh . leos && \
			if [ "$$BUILD_LEANOS" = "true" ]; then \
				patches/apply.sh . leanos; \
			fi && \
			rm -rf patches/'

# step 3: copy prebuilts to vendor/
copy-prebuilts: build-container
	$(call print_section,Copy prebuilts)
	$(CONTAINER_RUN) -w /repo/src \
		/bin/bash -e -c ' \
			rm -rfv vendor/common vendor/rom && \
			cp -Rfv /repo/external . && \
			cp -Rfv /repo/vendor . && \
			cp -Rfv vendor/$${$(ROM_PREFIX),,} vendor/rom'

# step 4: build treble app - compile the treble app
build-treble-app: build-container
	$(call print_section,Build Treble App)
	$(CONTAINER_RUN) -w /repo/src \
		/bin/bash -e -c ' \
			if [ -d treble_app ]; then \
				cd treble_app/ && \
					bash build.sh release; \
			fi'

# step 5a: build arm64 architecture
build-arm64:
	$(call build_arch,arm64,ARM64)

# step 5b: build arm32_binder64 architecture
build-arm32:
	$(call build_arch,a64,ARM32_BINDER64)

# step 6: prepare images - rename and compress image files in one step
prepare-images: build-container
	$(call print_section,Prepare Images)
	$(CONTAINER_RUN) -w /repo/tmp \
		/bin/bash -e -c ' \
			VERSION_TAG="$${$$(cat /repo/$(ANDROID_VERSION_FILE))#android-}-$$(cat /repo/$$BUILD_NUMBER_FILE)"; \
			for arch in $(ARCHITECTURES); do \
				src="system_$$arch.img"; \
				if [ -f "$$src" ]; then \
					case $$arch in \
						arm64) arch_name="arm64" ;; \
						a64) arch_name="arm32_binder64" ;; \
					esac; \
					dest="$(ROM_PREFIX)-$$arch_name-ab-$$VERSION_TAG.img"; \
					mv -v "$$src" "$$dest"; \
					xz -9 -T0 -v -z "$$dest"; \
				fi; \
			done && \
			cp -fv *.img.xz /repo/out/'

# step 7: upload images to github
upload-to-github:
	$(call print_section,Upload to GitHub)
	@cd $(PWD)/out/ && \
		git init && \
		git remote add origin "$(REPO_HOST)/$(REPO_PATH).git" && \
		RELEASE_TAG="$${$$(cat $(PWD)/$(ANDROID_VERSION_FILE))#android-}-$$(cat $(PWD)/$(BUILD_NUMBER_FILE))" && \
		gh repo set-default "$(REPO_PATH)" && \
		gh release create -d -n "" -t "$(ROM_PREFIX) $$RELEASE_TAG" "$$RELEASE_TAG" && \
		gh release upload "$$RELEASE_TAG" --clobber -- *.img.xz && \
		rm -rf .git/
