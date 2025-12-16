#!/bin/bash
set -e

# Base directory for the build
TOP=$(pwd)
DEVICE_DIR="device/xiaomi/nabu"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting crDroid Device Tree Adaptation for Nabu...${NC}"

if [ ! -d "$DEVICE_DIR" ]; then
    echo -e "${RED}Error: Device tree not found at $DEVICE_DIR. Please sync repo first.${NC}"
    exit 1
fi

cd "$DEVICE_DIR"

# Check if lineage_nabu.mk exists, meaning it's a fresh LineageOS tree
if [ -f "lineage_nabu.mk" ]; then
    echo -e "${GREEN}Renaming lineage_nabu.mk to crdroid_nabu.mk...${NC}"
    mv lineage_nabu.mk crdroid_nabu.mk

    echo -e "${GREEN}Adapting crdroid_nabu.mk for crDroid...${NC}"

    # Replace the inherit-product line
    # From: $(call inherit-product, vendor/lineage/config/common.mk)
    # To:   $(call inherit-product, vendor/crdroid/config/common.mk)
    sed -i 's|vendor/lineage/config/common.mk|vendor/crdroid/config/common.mk|g' crdroid_nabu.mk

    # Replace PRODUCT_NAME
    # From: PRODUCT_NAME := lineage_nabu
    # To:   PRODUCT_NAME := crdroid_nabu
    sed -i 's|PRODUCT_NAME := lineage_nabu|PRODUCT_NAME := crdroid_nabu|g' crdroid_nabu.mk

    # Also update AndroidProducts.mk
    if [ -f "AndroidProducts.mk" ]; then
        echo -e "${GREEN}Updating AndroidProducts.mk...${NC}"
        sed -i 's|lineage_nabu|crdroid_nabu|g' AndroidProducts.mk
    else
        echo -e "${RED}Warning: AndroidProducts.mk not found!${NC}"
    fi

    echo -e "${GREEN}Device tree adapted for crDroid successfully.${NC}"
elif [ -f "crdroid_nabu.mk" ]; then
    echo -e "${GREEN}crdroid_nabu.mk already exists. Skipping adaptation.${NC}"
else
    echo -e "${RED}Error: Neither lineage_nabu.mk nor crdroid_nabu.mk found. Is this the correct device tree?${NC}"
    exit 1
fi

cd "$TOP"
