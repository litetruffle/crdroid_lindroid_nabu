#!/bin/bash
set -e

# Base directory for the build
TOP=$(pwd)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Lindroid Integration Setup for Nabu...${NC}"

# Check if we are in the root of the source tree
if [ ! -d "build/make" ]; then
    echo -e "${RED}Error: Please run this script from the root of the Android source tree.${NC}"
    # In this specific context, the user might be running it in the repo I created,
    # but the instruction implies running it in the source tree.
    echo -e "${RED}Warning: 'build/make' not found. Assuming you are preparing the files to be copied to the source tree.${NC}"
fi

# 0. Adapt Device Tree for crDroid
if [ -f "setup_crdroid_tree.sh" ]; then
    ./setup_crdroid_tree.sh
else
    echo -e "${RED}Warning: setup_crdroid_tree.sh not found. Skipping device tree adaptation.${NC}"
fi

# 1. Apply frameworks/native patch
echo -e "${GREEN}Applying frameworks/native patch for Android 14...${NC}"
if [ -d "frameworks/native" ]; then
    cd frameworks/native
    # Using the LMODroid patch mentioned in the Gist for Android 14
    PATCH_URL="https://github.com/LMODroid/platform_frameworks_native/commit/51b680f33b66e06b18725fdf9a54fa923c14a10b.patch"

    wget "$PATCH_URL" -O lindroid.patch

    if git apply --check lindroid.patch; then
        git am lindroid.patch
        echo -e "${GREEN}Patch applied successfully.${NC}"
    else
        echo -e "${RED}Patch application failed or already applied. Aborting script to prevent inconsistencies.${NC}"
        rm lindroid.patch
        exit 1
    fi
    rm lindroid.patch
    cd "$TOP"
else
    echo -e "${RED}frameworks/native not found. Skipping patch application.${NC}"
fi

# 2. Modify Device Makefile
DEVICE_MK="device/xiaomi/nabu/device.mk"
echo -e "${GREEN}Modifying ${DEVICE_MK}...${NC}"

if [ -f "$DEVICE_MK" ]; then
    if ! grep -q "vendor/lindroid/lindroid.mk" "$DEVICE_MK"; then
        echo -e "\n# Lindroid Integration" >> "$DEVICE_MK"
        echo '$(call inherit-product, vendor/lindroid/lindroid.mk)' >> "$DEVICE_MK"
        echo -e "${GREEN}Added lindroid.mk inheritance to ${DEVICE_MK}.${NC}"
    else
        echo -e "${GREEN}Lindroid integration already present in ${DEVICE_MK}.${NC}"
    fi
else
    echo -e "${RED}${DEVICE_MK} not found. Skipping device makefile modification.${NC}"
fi

# 3. Modify BoardConfig for SELinux Permissive (Temporary)
BOARD_CONFIG="device/xiaomi/nabu/BoardConfig.mk"
echo -e "${GREEN}Modifying ${BOARD_CONFIG} for Permissive SELinux...${NC}"

if [ -f "$BOARD_CONFIG" ]; then
    if ! grep -q "androidboot.selinux=permissive" "$BOARD_CONFIG"; then
        echo -e "\n# Lindroid - Permissive SELinux" >> "$BOARD_CONFIG"
        echo 'BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive' >> "$BOARD_CONFIG"
        echo -e "${GREEN}Added permissive SELinux to ${BOARD_CONFIG}.${NC}"
    else
        echo -e "${GREEN}Permissive SELinux already present in ${BOARD_CONFIG}.${NC}"
    fi
else
    echo -e "${RED}${BOARD_CONFIG} not found. Skipping BoardConfig modification.${NC}"
fi

# 4. Update Kernel Config
KERNEL_CONFIG="kernel/xiaomi/nabu/arch/arm64/configs/nabu_defconfig"
# Fallback location
if [ ! -f "$KERNEL_CONFIG" ]; then
    KERNEL_CONFIG="kernel/xiaomi/nabu/arch/arm64/configs/vendor/nabu_defconfig"
fi

echo -e "${GREEN}Updating Kernel Config at ${KERNEL_CONFIG}...${NC}"

if [ -f "$KERNEL_CONFIG" ] && [ -f "lindroid_config.fragment" ]; then
    # Check if the config is already applied (checking one specific Lindroid config, e.g. CONFIG_VETH)
    # CONFIG_UTS_NS is common in Android, so we check for VETH which is LXC/Docker specific
    if ! grep -q "CONFIG_VETH=y" "$KERNEL_CONFIG"; then
        cat lindroid_config.fragment >> "$KERNEL_CONFIG"
        echo -e "${GREEN}Appended Lindroid config to ${KERNEL_CONFIG}.${NC}"
    else
         echo -e "${GREEN}Lindroid kernel config (VETH) seems to be already present in ${KERNEL_CONFIG}. Skipping append.${NC}"
    fi
else
    echo -e "${RED}Kernel config or lindroid_config.fragment not found. Skipping kernel config update.${NC}"
fi

echo -e "${GREEN}Lindroid setup complete!${NC}"
echo -e "Don't forget to sync the repositories defined in local_manifests/lindroid.xml before running this script."
