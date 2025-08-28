# leanos gsi builder justfile
#
# this justfile automates the process of building leanos gsi images for
# arm64 and arm32_binder64 architectures.

# variables
APPLY_DEBUG_PATCHES := "false"
ARCHITECTURES := "arm64 a64"
BUILD_NUMBER := `date "+%Y%m%d.%H%M%S"`
BUILD_DATETIME := `date "+%s"`
REPO_HOST := env_var_or_default("REPO_HOST", "https://github.com")
REPO_PATH := env_var_or_default("REPO_PATH", "cawilliamson/treble_leanos")
WEB_DIR := env_var_or_default("WEB_DIR", "/var/www/build.chrisaw.io")

# common container parameters
CONTAINER_RUN := "podman run --rm --privileged" + \
    " --pids-limit=0" + \
    " -v \"${HOME}/.android-certs:/certs:Z\"" + \
    " -v \"$(pwd):/repo:Z\"" + \
    " -v \"" + WEB_DIR + ":/web:Z\"" + \
    " -e APPLY_DEBUG_PATCHES=\"" + APPLY_DEBUG_PATCHES + "\"" + \
    " -e BUILD_DATETIME=\"" + BUILD_DATETIME + "\"" + \
    " -e BUILD_NUMBER=\"" + BUILD_NUMBER + "\""

# default target - runs the full build process
default: build-all

# clean all build directories to start fresh
clean:
    rm -rfv out/ src/ tmp/

# full build process - simple linear chain
build-all: build-container sync-sources prepare-sources build-treble-app build-arm64 build-arm32 prepare-images copy-to-webdir upload-to-github

# build the container image used for all build operations
build-container:
    podman build -t gsi-builder -f Containerfile .

# step 1: sync sources - clone ponces repo, extract versions, init manifest, and sync
sync-sources: build-container
    #!/usr/bin/env bash
    mkdir -p out/ src/ tmp/
    {{CONTAINER_RUN}} -w /repo/src gsi-builder \
        /bin/bash -e -c ' \
            echo "Sync sources..." && \
            rm -rf ponces_aosp/ && \
            git clone --depth=1 https://github.com/ponces/treble_aosp.git ponces_aosp/ && \
            grep "repo init" ponces_aosp/build.sh | sed "s/.*-b \([^ ]*\).*/\1/" > /repo/tmp/.android_version && \
            grep "lunch.*-.*-userdebug" ponces_aosp/build.sh | sed "s/.*\"\$$1\"-\([^-]*\)-.*/\1/" > /repo/tmp/.android_version_tag && \
            repo init -u https://android.googlesource.com/platform/manifest -b $(cat /repo/tmp/.android_version) --depth=1 --git-lfs && \
            mkdir -p .repo/local_manifests && \
            cp -v /repo/configs/*.xml .repo/local_manifests/ && \
            cp -v ponces_aosp/build/default.xml .repo/local_manifests/ponces_default.xml && \
            cp -v ponces_aosp/build/remove.xml .repo/local_manifests/ponces_remove.xml && \
            while ! repo sync -j$(nproc --all) --force-sync --no-clone-bundle --no-tags; do sleep 30; done'

# step 2: prepare sources - apply patches and copy prebuilts
prepare-sources: build-container
    {{CONTAINER_RUN}} -w /repo/src gsi-builder \
        /bin/bash -e -c ' \
            echo "Preparing sources..." && \
            rm -rf patches/ vendor/leanos && \
            cp -Rv /repo/patches . && \
            cp -Rv ponces_aosp/patches/trebledroid patches/ && \
            patches/apply.sh . trebledroid && \
            patches/apply.sh . staging && \
            if [ -d ponces_aosp/patches/staging ]; then \
                cp -Rv ponces_aosp/patches/staging patches/ponces_staging && \
                patches/apply.sh . ponces_staging; \
            fi; \
            patches/apply.sh . leanos && \
            cp -Rfv /repo/external . && \
            cp -Rfv /repo/vendor vendor/leanos && \
            if [ "{{APPLY_DEBUG_PATCHES}}" = "true" ]; then \
                patches/apply.sh . debug; \
            fi'

# step 3: build treble app - compile the treble app
build-treble-app: build-container
    {{CONTAINER_RUN}} -w /repo/src/treble_app gsi-builder \
        /bin/bash -e -c '
            echo "Building TrebleApp..." && \
            bash build.sh release
        '

# build architecture-specific targets
build_arch arch display_name:
    {{CONTAINER_RUN}} -w /repo/src gsi-builder \
        /bin/bash -e -c ' \
            echo "Building system image..." && \
            ANDROID_VERSION_TAG_VAL=$(cat /repo/tmp/.android_version_tag) && \
            pushd device/phh/treble && \
                cp -fv "/repo/configs/leanos.mk" . && \
                bash generate.sh leanos && \
            popd && \
            rm -rfv out/target/product/tdgsi_{{arch}}_ab/ && \
            . build/envsetup.sh && \
            lunch treble_{{arch}}_bvN-${ANDROID_VERSION_TAG_VAL}-userdebug && \
            make systemimage -j$(nproc --all) && \
            make target-files-package otatools -j$(nproc --all) && \
            bash vendor/leanos/keys/sign.sh && \
            rm -fv ${OUT}/system.img && \
            unzip -joq ${OUT}/signed-target_files.zip IMAGES/system.img -d ${OUT}/ && \
            rm -fv ${OUT}/signed-target_files.zip && \
            mv -v ${OUT}/system.img /repo/tmp/system_{{arch}}.img'

# step 4a: build arm64 architecture
build-arm64:
    @just build_arch "arm64" "ARM64"

# step 4b: build arm32_binder64 architecture
build-arm32:
    @just build_arch "a64" "ARM32_BINDER64"

# step 5: prepare images - rename and compress image files in one step
prepare-images: build-container
    {{CONTAINER_RUN}} -w /repo/tmp gsi-builder \
        /bin/bash -e -c ' \
            ANDROID_VERSION=$(cat /repo/tmp/.android_version); \
            VERSION_TAG="${ANDROID_VERSION#android-}-{{BUILD_NUMBER}}"; \
            for arch in {{ARCHITECTURES}}; do \
                src="system_${arch}.img"; \
                if [ -f "${src}" ]; then \
                    dest="LeanOS-${arch}-ab-${VERSION_TAG}.img"; \
                    mv -v "${src}" "${dest}"; \
                    xz -9 -T0 -v -z "${dest}"; \
                fi; \
            done && \
            cp -fv *.img.xz /repo/out/'

# step 6: copy images to web directory
copy-to-webdir: build-container
    {{CONTAINER_RUN}} -w /repo/tmp gsi-builder \
        /bin/bash -e -c ' \
            echo "Copying to webdir..." && \
            ANDROID_VERSION=$(cat /repo/tmp/.android_version); \
            VERSION_TAG="${ANDROID_VERSION#android-}-{{BUILD_NUMBER}}"; \
            RELEASE_NAME="LeanOS-ab-${VERSION_TAG}"; \
            mkdir -p "/web/${RELEASE_NAME}" && \
            cp -fv *.img.xz "/web/${RELEASE_NAME}/" && \
            echo "Images copied to /web/${RELEASE_NAME}/"'

# step 7: upload images to github
upload-to-github:
    #!/usr/bin/env bash
    cd "$(pwd)/out/" && \
        echo "Uploading to GitHub..." && \
        git init && \
        git remote add origin "{{REPO_HOST}}/{{REPO_PATH}}.git" && \
        ANDROID_VERSION=$(cat "$(pwd)/tmp/.android_version") && \
        RELEASE_TAG="${ANDROID_VERSION#android-}-{{BUILD_NUMBER}}" && \
        gh repo set-default "{{REPO_PATH}}" && \
        RELEASE_NAME="LeanOS-ab-${RELEASE_TAG}" && \
        RELEASE_DESCRIPTION="Download mirror: https://build.chrisaw.io/${RELEASE_NAME}/" && \
        gh release create -d -n "${RELEASE_DESCRIPTION}" -t "LeanOS ${RELEASE_TAG}" "${RELEASE_TAG}" && \
        gh release upload "${RELEASE_TAG}" --clobber -- *.img.xz && \
        rm -rf .git/
