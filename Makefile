# LeOS GSI Builder Makefile
#
# This Makefile automates the process of building LeOS GSI images for
# arm64 and arm32_binder64 architectures.
#
# Make sure Make stops if any command fails
.SHELLFLAGS := -e -c
.ONESHELL:

# Define a function to print section headers
define print_section
	@echo ""
	@echo "#######################"
	@echo "# $(1)"
	@echo "#######################"
	@echo ""
endef

#######################
# Configuration variables
#######################

# ROM configuration
BUILD_LEANOS ?= false
BUILD_DATE := $(shell date "+%Y%m%d")
BUILD_TIME := $(shell date "+%H%M%S")
PONCES_AOSP_TAG ?= android-16.0
VERIFY_SEPOLICY ?= true
UPLOAD_TO_GITHUB ?= false

# Build variants configuration
ARCHITECTURES := arm64 a64
ARCH_DISPLAY_NAMES := arm64 arm32_binder64

# Resource configuration
MAX_CPU_PERCENT ?= 100
MAX_MEM_PERCENT ?= 100

# Container configuration
CONTAINER_RUNTIME ?= podman

# System variables
ANDROID_VERSION_FILE := tmp/.android_version
ANDROID_VERSION_TAG_FILE := tmp/.android_version_tag
BUILD_NUMBER_FILE := tmp/.build_number
$(shell mkdir -p tmp)
ifeq ($(wildcard $(BUILD_NUMBER_FILE)),)
    $(shell echo "$(BUILD_DATE).$(BUILD_TIME)" > $(BUILD_NUMBER_FILE))
endif
BUILD_NUMBER := $(shell cat $(BUILD_NUMBER_FILE))

# Common container parameters
CONTAINER_RUN = $(CONTAINER_RUNTIME) run --rm --privileged \
	--pids-limit=0 \
	-v "$(PWD):/repo:Z" \
	-e ANDROID_VERSION_FILE="$(ANDROID_VERSION_FILE)" \
	-e ANDROID_VERSION_TAG_FILE="$(ANDROID_VERSION_TAG_FILE)" \
	-e BUILD_LEANOS="$(BUILD_LEANOS)" \
	-e BUILD_DATE="$(BUILD_DATE)" \
	-e BUILD_NUMBER="$(BUILD_NUMBER)" \
	-e BUILD_NUMBER_FILE="$(BUILD_NUMBER_FILE)"

#######################
# Define all phony targets
#######################
.PHONY: all apply-patches build-arm32 build-arm64 build-container build-prerequisites build-treble-app \
	clean clone-ponces-aosp-repo compress-images copy-manifest-config copy-prebuilts create-folders \
	extract-android-version full-build init-aosp-manifest post-build rename-images \
	sync-sources upload-to-github

#######################
# Main targets
#######################

# Default target - runs the full build process
all: full-build

# Clean all build directories to start fresh
clean:
	rm -rfv out/ src/ tmp/

# Build the container image used for all build operations
build-container:
	$(CONTAINER_RUNTIME) build -t leos-gsi-builder -f Containerfile .

# Create necessary directories for the build process
create-folders:
	mkdir -p out/ src/ tmp/
	rm -rf tmp/*

# Build targets for each architecture
build-arm64: build-prerequisites
	$(call print_section,Build ARM64)
	$(call build_gsi_variant,arm64,$(VERIFY_SEPOLICY))

build-arm32: build-prerequisites
	$(call print_section,Build ARM32_BINDER64)
	$(call build_gsi_variant,a64,$(VERIFY_SEPOLICY))

# Full build process
full-build: extract-android-version init-aosp-manifest copy-manifest-config sync-sources \
	apply-patches  copy-prebuilts \
	build-treble-app build-arm64 build-arm32 post-build

# Common build prerequisites
build-prerequisites: build-container create-folders extract-android-version copy-manifest-config sync-sources apply-patches  copy-prebuilts build-treble-app

# Post-build steps
post-build: rename-images compress-images
	@if [ "$(UPLOAD_TO_GITHUB)" = "true" ]; then \
		$(MAKE) upload-to-github; \
	fi

#######################
# Build steps
#######################

# Step 1: Clone ponces AOSP manifest
clone-ponces-aosp-repo: build-container create-folders
	$(call print_section,Clone ponces-aosp repo)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src/ && \
				rm -rf ponces_aosp/ && \
				git clone --depth=1 https://github.com/ponces/treble_aosp.git -b $(PONCES_AOSP_TAG) ponces_aosp/ && \
			popd'

# Step 2: Extract Android version and version tag from ponces repo
extract-android-version: clone-ponces-aosp-repo
	$(call print_section,Extract Android Version and Version Tag)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src/ && \
				ANDROID_VERSION=$$(grep "repo init" ponces_aosp/build.sh | sed "s/.*-b \([^ ]*\).*/\1/") && \
				ANDROID_VERSION_TAG=$$(grep "lunch.*-.*-userdebug" ponces_aosp/build.sh | sed "s/.*\"\$$1\"-\([^-]*\)-.*/\1/") && \
				echo "Extracted Android version: $$ANDROID_VERSION" && \
				echo "Extracted Android version tag: $$ANDROID_VERSION_TAG" && \
				echo "$$ANDROID_VERSION" > /repo/$(ANDROID_VERSION_FILE) && \
				echo "$$ANDROID_VERSION_TAG" > /repo/$(ANDROID_VERSION_TAG_FILE) && \
			popd'

# Step 3: Init AOSP manifest
init-aosp-manifest: extract-android-version
	$(call print_section,Init AOSP manifest)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src/ && \
				ANDROID_VERSION=$$(cat /repo/$(ANDROID_VERSION_FILE)) && \
				echo "Using Android version: $$ANDROID_VERSION" && \
				repo init -u https://android.googlesource.com/platform/manifest -b $$ANDROID_VERSION --depth=1 --git-lfs && \
			popd'

# Step 4: Copy manifest config - Add local manifest files to customize the source tree
copy-manifest-config: build-container create-folders
	$(call print_section,Copy manifest config)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			mkdir -p /repo/src/.repo/local_manifests && \
			cp -v /repo/configs/*.xml /repo/src/.repo/local_manifests/ && \
			cp -v /repo/src/ponces_aosp/build/default.xml /repo/src/.repo/local_manifests/ponces_default.xml && \
			cp -v /repo/src/ponces_aosp/build/remove.xml /repo/src/.repo/local_manifests/ponces_remove.xml'

# Step 5: Perform full sources sync - Download all source code with automatic retry on failure
sync-sources: build-container create-folders
	$(call print_section,Sync Sources)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src/ && \
				until repo sync -c -j$$(nproc --all) --force-sync --no-clone-bundle --no-tags; do \
					echo "Sync failed, retrying in 30 seconds..."; \
					sleep 30; \
				done && \
			popd'

# Step 6: Apply patches - Apply LeOS patches to the source
apply-patches: build-container create-folders
	$(call print_section,Apply Patches)
	$(CONTAINER_RUN) \
		leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src/ && \
				rm -rf patches/ && \
				cp -Rv /repo/patches . && \
				cp -Rv ponces_aosp/patches/trebledroid patches/ && \
				cp -Rv ponces_aosp/patches/staging patches/ponces_staging && \
				patches/apply.sh . trebledroid && \
				patches/apply.sh . ponces_staging && \
				patches/apply.sh . leos && \
				if [ "$$BUILD_LEANOS" = "true" ]; then \
					patches/apply.sh . leanos; \
				fi && \
				rm -rf patches/ && \
			popd'

# Step 7: Copy prebuilts to vendor/
copy-prebuilts: build-container create-folders
	$(call print_section,Copy prebuilts)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src && \
				rm -rfv vendor/LeOS && \
				cp -Rfv /repo/external . && \
				cp -Rfv /repo/packages . && \
				if [ "$$BUILD_LEANOS" = "true" ]; then \
					echo "BUILD_LEANOS=true: Copying vendor/LeOS_microg to src/vendor/LeOS"; \
					cp -Rfv /repo/vendor/LeOS_microg vendor/LeOS; \
				else \
					echo "BUILD_LEANOS=false: Copying vendor/LeOS_standard to src/vendor/LeOS"; \
					cp -Rfv /repo/vendor/LeOS_standard vendor/LeOS; \
				fi && \
			popd'

# Step 8: Build treble app - Compile the Treble App
build-treble-app: build-container create-folders
	$(call print_section,Build Treble App)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src && \
				if [ -d treble_app ]; then \
					pushd treble_app/ && \
						bash build.sh release && \
					popd; \
				fi && \
			popd'

# Step 9: Helper function to build a specific GSI variant
define build_gsi_variant
	$(CONTAINER_RUN) \
	-e ARCH="$(1)" \
	leos-gsi-builder \
	/bin/bash -e -c ' \
		pushd /repo/src && \
			ANDROID_VERSION_TAG_VAL=$$(cat /repo/$(ANDROID_VERSION_TAG_FILE)) && \
			echo "Building $(1) with Android version tag: $$ANDROID_VERSION_TAG_VAL" && \
			pushd device/phh/treble && \
				cp -fv "/repo/configs/leos.mk" leos.mk && \
				bash generate.sh leos && \
			popd && \
			rm -rfv out/target/product/leos_$(1)_ab/ && \
			. build/envsetup.sh && \
			lunch leos_$(1)_bvN-$$ANDROID_VERSION_TAG_VAL-userdebug && \
			make systemimage -j$$(nproc --all) && \
			if [ "$(2)" = "true" ]; then \
				make vndk-test-sepolicy -j$$(nproc --all); \
			fi && \
			rm -Rfv vendor/partner_gms && \
			mv -v out/target/product/leos_$(1)_ab/system.img /repo/tmp/system_$(1).img && \
		popd'
endef

# Step 10: Rename image files - Convert temporary image names to final release filenames
rename-images: build-container create-folders
	$(call print_section,Rename Images)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/tmp && \
			archs=("arm64" "a64"); \
			arch_names=("arm64" "arm32_binder64"); \
			ANDROID_VERSION_TAG_VAL=$$(cat /repo/$(ANDROID_VERSION_TAG_FILE)); \
			BUILD_NUMBER_VAL=$$(cat /repo/$$BUILD_NUMBER_FILE); \
			echo "Using Android version tag for filenames: $$ANDROID_VERSION_TAG_VAL"; \
			for j in $${!archs[@]}; do \
				src="system_$${archs[j]}.img"; \
				if [ -f "$$src" ]; then \
					dest="LeOS-$${arch_names[j]}-ab-$$ANDROID_VERSION_TAG_VAL-$$BUILD_NUMBER_VAL-UNOFFICIAL.img"; \
					mv -v "$$src" "$$dest"; \
				fi; \
			done && \
			popd'

# Step 11: Compress all images with xz
compress-images: build-container create-folders
	$(call print_section,Compress Images)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/tmp && \
				find . -maxdepth 1 -name "*.img" -exec xz -9 -T0 -v -z "{}" \; && \
				cp -fv *.img.xz /repo/out/ && \
			popd'

# Step 12: Upload images to GitHub
upload-to-github: create-folders
	$(call print_section,Upload to GitHub)
	@if ! command -v gh &> /dev/null; then \
		echo "Error: GitHub CLI (gh) is not installed. Please install it first." >&2; \
		exit 1; \
	fi
	@cd $(PWD)/out/ && \
		git init && \
		git remote add origin "https://github.com/cawilliamson/treble_leos.git" && \
		gh repo set-default "cawilliamson/treble_leos" && \
		ANDROID_VERSION_TAG_VAL=$$(cat $(PWD)/$(ANDROID_VERSION_TAG_FILE)) && \
		BUILD_NUMBER_VAL=$$(cat $(PWD)/$(BUILD_NUMBER_FILE)) && \
		echo "Using Android version tag for GitHub release: $$ANDROID_VERSION_TAG_VAL" && \
		gh release create -d -n "" -t "LeOS $$ANDROID_VERSION_TAG_VAL-$$BUILD_NUMBER_VAL" "$$ANDROID_VERSION_TAG_VAL-$$BUILD_NUMBER_VAL" && \
		gh release upload "$$ANDROID_VERSION_TAG_VAL-$$BUILD_NUMBER_VAL" --clobber -- *.img.xz && \
		rm -rf .git/
