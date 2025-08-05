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
ANDROID_VERSION_TAG ?= bp2a
APPLY_DEBUG_PATCHES ?= false
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
BUILD_NUMBER_FILE := tmp/.build_number
$(shell mkdir -p tmp)
ifeq ($(wildcard $(BUILD_NUMBER_FILE)),)
    $(shell echo "$(BUILD_DATE).$(BUILD_TIME)" > $(BUILD_NUMBER_FILE))
endif
BUILD_NUMBER := $(shell cat $(BUILD_NUMBER_FILE))
CPU_LIMIT := $(shell echo $$(( $(shell nproc --all) * $(MAX_CPU_PERCENT) / 100 )))
MEM_LIMIT := $(shell echo "$$(( $(shell free -m | awk '/^Mem:/{print $$2}') * $(MAX_MEM_PERCENT) / 100 ))m")

# Common container parameters
CONTAINER_RUN = $(CONTAINER_RUNTIME) run --rm --privileged \
	--cpus="$(CPU_LIMIT)" \
	--memory="$(MEM_LIMIT)" \
	--pids-limit=0 \
	-v "$(PWD):/repo:Z" \
	-e BUILD_DATE="$(BUILD_DATE)" \
	-e BUILD_NUMBER="$(BUILD_NUMBER)" \
	-e BUILD_NUMBER_FILE="$(BUILD_NUMBER_FILE)" \
	-e APPLY_DEBUG_PATCHES="$(APPLY_DEBUG_PATCHES)"

#######################
# Define all phony targets
#######################
.PHONY: all build-container build-prerequisites build-treble-app \
	clean clone-ponces-aosp-repo compress-images copy-manifest-config create-folders \
	full-build copy-prebuilts init-aosp-manifest post-build rename-images \
	sync-sources upload-to-github build-arm64 build-arm32

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
	$(call build_gsi_variant,arm64,$(VERIFY_SEPOLICY),$(ANDROID_VERSION_TAG))

build-arm32: build-prerequisites
	$(call print_section,Build ARM32_BINDER64)
	$(call build_gsi_variant,a64,$(VERIFY_SEPOLICY),$(ANDROID_VERSION_TAG))

# Full build process
full-build: clone-ponces-aosp-repo init-aosp-manifest copy-manifest-config sync-sources \
	apply-patches  copy-prebuilts \
	build-treble-app build-arm64 build-arm32 post-build

# Common build prerequisites
build-prerequisites: build-container create-folders clone-ponces-aosp-repo copy-manifest-config sync-sources apply-patches  copy-prebuilts build-treble-app

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

# Step 2: Init AOSP manifest
init-aosp-manifest: build-container create-folders
	$(call print_section,Init AOSP manifest)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src/ && \
				ANDROID_TAG=$$(grep "repo init" ponces_aosp/build.sh | sed "s/.*-b \([^ ]*\).*/\1/") && \
				repo init -u https://android.googlesource.com/platform/manifest -b $$ANDROID_TAG --depth=1 --git-lfs && \
			popd'

# Step 3: Copy manifest config - Add local manifest files to customize the source tree
copy-manifest-config: build-container create-folders
	$(call print_section,Copy manifest config)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			mkdir -p /repo/src/.repo/local_manifests && \
			cp -v /repo/configs/*.xml /repo/src/.repo/local_manifests/ && \
			cp -v /repo/src/ponces_aosp/build/default.xml /repo/src/.repo/local_manifests/ponces_default.xml && \
			cp -v /repo/src/ponces_aosp/build/remove.xml /repo/src/.repo/local_manifests/ponces_remove.xml'

# Step 4: Perform full sources sync - Download all source code with automatic retry on failure
sync-sources: build-container create-folders
	$(call print_section,Sync Sources)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src/ && \
				until repo sync -c -j$(CPU_LIMIT) --force-sync --no-clone-bundle --no-tags; do \
					echo "Sync failed, retrying in 30 seconds..."; \
					sleep 30; \
				done && \
			popd'

# Step 5: Apply patches - Apply LeOS patches to the source
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
				patches/apply.sh . personal && \
				if [ "$$APPLY_DEBUG_PATCHES" = "true" ]; then \
					patches/apply.sh . debug; \
				fi && \
				rm -rf patches/ && \
			popd'

# Step 6: Generate signing keys - Create keys for signing the build
copy-prebuilts: build-container create-folders
	$(call print_section,Copy prebuilts)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/src && \
				cp -Rfv /repo/external . && \
				cp -Rfv /repo/packages . && \
				cp -Rfv /repo/vendor . && \
			popd'

# Step 7: Build treble app - Compile the Treble App
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

# Step 8: Helper function to build a specific GSI variant
define build_gsi_variant
	$(CONTAINER_RUN) \
	-e ARCH="$(1)" \
	leos-gsi-builder \
	/bin/bash -e -c ' \
		pushd /repo/src && \
			pushd device/phh/treble && \
				cp -fv "/repo/configs/leos.mk" leos.mk && \
				bash generate.sh leos && \
			popd && \
			rm -rfv out/target/product/leos_$(1)_ab/ && \
			. build/envsetup.sh && \
			lunch leos_$(1)_bvN-$(3)-userdebug && \
			make systemimage -j$(CPU_LIMIT) && \
			if [ "$(2)" = "true" ]; then \
				make vndk-test-sepolicy -j$(CPU_LIMIT); \
			fi && \
			rm -Rfv vendor/partner_gms && \
			mv -v out/target/product/leos_$(1)_ab/system.img /repo/tmp/system_$(1).img && \
		popd'
endef

# Step 9: Rename image files - Convert temporary image names to final release filenames
rename-images: build-container create-folders
	$(call print_section,Rename Images)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/tmp && \
			archs=("arm64" "a64"); \
			arch_names=("arm64" "arm32_binder64"); \
			BUILD_NUMBER_VAL=$$(cat /repo/$$BUILD_NUMBER_FILE); \
			for j in $${!archs[@]}; do \
				src="system_$${archs[j]}.img"; \
				if [ -f "$$src" ]; then \
					dest="LeOS-$${arch_names[j]}-ab-$(ANDROID_VERSION_TAG)-$$BUILD_NUMBER_VAL-UNOFFICIAL.img"; \
					mv -v "$$src" "$$dest"; \
				fi; \
			done && \
			popd'

# Step 10: Compress all images with xz
compress-images: build-container create-folders
	$(call print_section,Compress Images)
	$(CONTAINER_RUN) leos-gsi-builder \
		/bin/bash -e -c ' \
			pushd /repo/tmp && \
				find . -maxdepth 1 -name "*.img" -exec xz -9 -T0 -v -z "{}" \; && \
				cp -fv *.img.xz /repo/out/ && \
			popd'

# Step 11: Upload images to GitHub
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
		BUILD_NUMBER_VAL=$$(cat $(PWD)/$(BUILD_NUMBER_FILE)) && \
		gh release create -d -n "" -t "LeOS $(ANDROID_VERSION_TAG)-$$BUILD_NUMBER_VAL" "$(ANDROID_VERSION_TAG)-$$BUILD_NUMBER_VAL" && \
		gh release upload "$(ANDROID_VERSION_TAG)-$$BUILD_NUMBER_VAL" --clobber -- *.img.xz && \
		rm -rf .git/
