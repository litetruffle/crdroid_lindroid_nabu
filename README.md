# Lindroid Integration for Xiaomi Pad 5 (nabu) on crDroid

This repository contains the necessary files and scripts to integrate Lindroid (Linux on Android) into the crDroid build for the Xiaomi Pad 5 (nabu).

## Prerequisites

- A working Android build environment (Ubuntu 20.04/22.04 recommended).
- `repo` tool installed.
- Basic knowledge of building Android ROMs.

## Instructions

### 1. Initialize the Build Environment

If you haven't already initialized the crDroid source tree:

```bash
mkdir crdroid
cd crdroid
repo init -u https://github.com/crdroidandroid/android.git -b 14.0 --git-lfs
```

### 2. Add Local Manifests

Copy the `local_manifests` directory from this repo to `.repo/local_manifests` in your build tree. This configures the LineageOS device tree and Lindroid dependencies.

```bash
# Assuming you cloned this repo to ~/lindroid-nabu-integration
mkdir -p .repo/local_manifests
cp ~/lindroid-nabu-integration/local_manifests/lindroid.xml .repo/local_manifests/
```

### 3. Sync Repositories

Sync the source code.

```bash
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
```

### 4. Apply Patches and Configuration

Copy the setup scripts and config fragment to the root of your source tree and run the main setup script.

```bash
cp ~/lindroid-nabu-integration/setup_lindroid.sh .
cp ~/lindroid-nabu-integration/setup_crdroid_tree.sh .
cp ~/lindroid-nabu-integration/lindroid_config.fragment .
chmod +x setup_lindroid.sh setup_crdroid_tree.sh
./setup_lindroid.sh
```

This script will:
1. **Adapt Device Tree**: Convert the fetched LineageOS device tree to support crDroid (renames `lineage_nabu.mk` to `crdroid_nabu.mk` and updates inheritance).
2. **Apply Patch**: Apply the required `frameworks/native` patch for LXC support.
3. **Configure Device**: Modify `device/xiaomi/nabu/device.mk` to inherit Lindroid settings and enable permissive SELinux in `BoardConfig.mk`.
4. **Configure Kernel**: Append the LXC/Docker kernel configurations to the nabu kernel config.

### 5. Build

Set up the build environment and start the build. Note that the product name is now `crdroid_nabu`.

```bash
. build/envsetup.sh
lunch crdroid_nabu-userdebug
mka bacon
```

## Post-Install

After flashing the ROM:
1. Download the Lindroid rootfs.
2. Follow the instructions in the Lindroid App/Guide to set up the Linux container.

## Credits

- [Lindroid Project](https://github.com/Linux-on-droid)
- [alghiffaryfa19](https://github.com/alghiffaryfa19) for the initial guide.
- [AngelaCooljx](https://gist.github.com/AngelaCooljx) for the detailed guide.
