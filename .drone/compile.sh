#!/usr/bin/env bash
# Drone CI kernel pipeline - build script


#### PREPARE ####

# Log all commands executed and exit on error
set -ve

# Exit if skip marker is present
[[ -f "$DRONE_WORKSPACE/skip_exec" ]] && exit

# Sync kernel build number with Drone
export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER


#### COMPILE ####

# Load helpers
# Temporarily disable verbose mode here to reduce spam
set +v
echo source setup.sh
source setup.sh
set -v

# Update/initialize config
mc

# Disable native CPU-specific optimizations
scripts/config --file out/.config -d MNATIVE -e GENERIC_CPU

# Compile kernel
time kmake | tee "$DRONE_WORKSPACE/compile.log"


#### FINALIZE ####

# Get short commit hash
SHORT_HASH=$(cut -c-8 <<< $DRONE_COMMIT)

# Copy and rename product
PRODUCT_NAME="ProtonKernel-wsl2-ci$DRONE_BUILD_NUMBER-$SHORT_HASH.bin"
cp out/arch/x86/boot/compressed/vmlinux.bin "$PRODUCT_NAME"

echo "$PRODUCT_NAME" > out/product_name.txt

# Show compiled kernel's version string
zver "$PRODUCT_NAME"
