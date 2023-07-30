WORKSPACE=${HOME}/KernelSU_for_Polaris_PE
Actor=Shuery
DOWNLOAD_KERNEL_SOURCE=true
KERNEL_SOURCE=https://github.com/PixelExperience-Devices/kernel_xiaomi_polaris
KERNEL_SOURCE_BRANCH=thirteen
KERNEL_CONFIG=polaris_defconfig
KERNEL_IMAGE_NAME=Image.gz-dtb
ARCH=arm64
EXTRA_CMDS="LD=ld.lld"

# Clang
## Custom
USE_CUSTOM_CLANG=true
CUSTOM_CLANG_SOURCE=https://github.com/kdrag0n/proton-clang
CUSTOM_CLANG_TAG=
CUSTOM_CLANG_TYPE=git
CUSTOM_CLANG_BRANCH=master
CLONE_CUSTOM_CLANG=true

### if your set USE CUSTOM CLANG to false than DO NOT CHANGE CUSTOM CMDS
CUSTOM_CMDS="CLANG_TRIPLE=aarch64-linux-gnu-"

## AOSP
CLANG_BRANCH=master-kernel-build-2022
CLANG_VERSION=r450784d

# GCC
ENABLE_GCC_ARM64=true
ENABLE_GCC_ARM32=true

## AOSP
USE_GCC_TAG=true
GCC_TAG=android-13.0.0_r0.102
USE_GCC_COMMIT_ID=false
GCC_COMMIT_ID=d7d824eaa0690179c4b504209dbb017dfc730cf3

## Clang
USE_CLANG_GCC=true

# KernelSU flags
ENABLE_KERNELSU=true
KERNELSU_TAG=
KSU_EXPECTED_SIZE=
KSU_EXPECTED_HASH=

# Configuration
DISABLE_LTO=true
DISABLE_CC_WERROR=true
ADD_KPROBES_CONFIG=true
ADD_OVERLAYFS_CONFIG=true

# AnyKernel3
ANYKERNEL_DEVICE_NAME_1=polairs
ANYKERNEL_DEVICE_NAME_2=
ANYKERNEL_DEVICE_NAME_3=
ANYKERNEL_DEVICE_NAME_4=
ANYKERNEL_DEVICE_NAME_5=
ANYKERNEL_BLOCK=/dev/block/bootdevice/by-name/boot
ANYKERNEL_IS_SLOT_DEVICE=0

# Ccache
ENABLE_CCACHE=false

# DTBO image
NEED_DTBO=false

# Build boot images
BUILD_BOOT_IMG=false
SOURCE_BOOT_IMAGE=${WORKSPACE}/boot/boot.img

# Setup build kernel environment
BUILD_TIME=$(TZ=Asia/Shanghai date "+%Y%m%d%H%M")
DEVICE=$(echo ${KERNEL_CONFIG} | sed 's!vendor/!!;s/_defconfig//;s/_user//;s/-perf//')
sudo apt-get update
sudo apt-get install git ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip device-tree-compiler python2 python3 -y
mkdir -p $WORKSPACE/kernel_workspace

# Download Clang-aosp
if [ ${USE_CUSTOM_CLANG} == false ]; then
    cd $WORKSPACE/kernel_workspace
    if [ -f "$WORKSPACE/kernel_workspace/clang-${CLANG_VERSION}.tar.gz" ]; then
        if [ -d "$WORKSPACE/kernel_workspace/clang-aosp" ]; then
            echo "Clang-AOSP already exists."
        else
            mkdir clang-aosp
            tar -C clang-aosp/ -zxvf clang-${CLANG_VERSION}.tar.gz
        fi
    else
        if [ -d "$WORKSPACE/kernel_workspace/clang-aosp" ]; then
            rm -rf $WORKSPACE/kernel_workspace/clang-aosp
        fi
        mkdir clang-aosp
        wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/${CLANG_BRANCH}/clang-${CLANG_VERSION}.tar.gz
        tar -C clang-aosp/ -zxvf clang-${CLANG_VERSION}.tar.gz
    fi
fi

# Download Custom-Clang
if [ ${USE_CUSTOM_CLANG} == true ]; then
    cd $WORKSPACE/kernel_workspace
    if [ ${CUSTOM_CLANG_TYPE} == "tar.zst" ]; then
        sudo apt-get install zstd -y
        if [ -f "clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}" ]; then
            if [ -d "clang-aosp" ]; then
                echo "Custom Clang exits."
            else
                tar -C clang-aosp/ -I zstd -xvf clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
                cd clang-aosp
                bash ${WORKSPACE}/patch-for-old-glibc.sh
            fi
        else
            if [ -d "clang-aosp" ]; then
                rm -rf clang-aosp
            fi
            mkdir clang-aosp
            wget -O clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE} ${CUSTOM_CLANG_SOURCE}/releases/download/${CUSTOM_CLANG_TAG}/neutron-clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
            tar -C clang-aosp/ -I zstd -xvf clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
            cd clang-aosp
            bash ${WORKSPACE}/patch-for-old-glibc.sh
        fi
    fi
    if [ ${CUSTOM_CLANG_TYPE} == "zip" ]; then
        if [ -f "clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}" ]; then
            if [ -d "clang-aosp" ]; then
                echo "Custom Clang exits."
            else
                unzip -d clang-aosp/ clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
            fi
        else
            if [ -d "clang-aosp" ]; then
                rm -rf clang-aosp
            fi
            mkdir clang-aosp
            wget -O clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE} ${CUSTOM_CLANG_SOURCE}/archive/ref/tags/${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
            unzip -d clang-aosp/ clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
        fi
    fi
    if [ ${CUSTOM_CLANG_TYPE} == "tar.gz" ]; then
        if [ -f "clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}" ]; then
            if [ -d "clang-aosp" ]; then
                echo "Custom Clang exits."
            else
                tar -C clang-aosp/ -zxvf clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
            fi
        else
            if [ -d "clang-aosp" ]; then
                rm -rf clang-aosp
            fi
            mkdir clang-aosp
            wget -O clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE} ${CUSTOM_CLANG_SOURCE}/archive/ref/tags/${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
            tar -C clang-aosp/ -zxvf clang-${CUSTOM_CLANG_TAG}.${CUSTOM_CLANG_TYPE}
        fi
    fi
    if [ ${CUSTOM_CLANG_TYPE} == "git" ]; then
        if [ ${CLONE_CUSTOM_CLANG} == true ]; then
            if [ -d "clang-aosp" ]; then
                rm -rf clang-aosp
            fi
            git clone ${CUSTOM_CLANG_SOURCE} -b ${CUSTOM_CLANG_BRANCH} --depth=1 clang-aosp/
        fi
    fi
fi

# Download Gcc-aosp
cd $WORKSPACE/kernel_workspace
if [ ${ENABLE_GCC_ARM64} = true ]; then
    if [ ${USE_CLANG_GCC} = true]; then
        GCC_64="CROSS_COMPILE=aarch64-linux-gnu-"
    else
        if [ ${USE_GCC_TAG} = true ]; then
            if [ -f "$WORKSPACE/kernel_workspace/gcc-${GCC_TAG}-64.tar.gz" ]; then
                if [ -d "$WORKSPACE/kernel_workspace/gcc-64" ]; then
                    echo "GCC-ARM64 already exists."
                else
                    mkdir gcc-64
                    tar -C gcc-64/ -zxvf gcc-${GCC_TAG}-64.tar.gz
                fi
            else
                if [ -d "$WORKSPACE/kernel_workspace/gcc-64" ]; then
                    rm -rf $WORKSPACE/kernel_workspace/gcc-64
                fi
                mkdir gcc-64
                wget -O gcc-${GCC_TAG}-64.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/tags/${GCC_TAG}.tar.gz
                tar -C gcc-64/ -zxvf gcc-${GCC_TAG}-64.tar.gz
            fi
        fi
        if [ ${USE_GCC_COMMIT_ID} = true ]; then
            if [ -f "$WORKSPACE/kernel_workspace/gcc-${GCC_COMMIT_ID}-64.tar.gz" ]; then
                if [ -d "$WORKSPACE/kernel_workspace/gcc-64" ]; then
                    echo "GCC-ARM64 already exists."
                else
                    mkdir gcc-64
                    tar -C gcc-64/ -zxvf gcc-${GCC_COMMIT_ID}-64.tar.gz
                fi
            else
                if [ -d "$WORKSPACE/kernel_workspace/gcc-64" ]; then
                    rm -rf $WORKSPACE/kernel_workspace/gcc-64
                fi
                mkdir gcc-64
                wget -O gcc-${GCC_COMMIT_ID}-64.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/${GCC_COMMIT_ID}.tar.gz
                tar -C gcc-64/ -zxvf gcc-${GCC_COMMIT_ID}-64.tar.gz
            fi
        fi
        GCC_64="CROSS_COMPILE=$WORKSPACE/kernel_workspace/gcc-64/bin/aarch64-linux-android-"
    fi
fi
if [ ${ENABLE_GCC_ARM32} = true ]; then
    if [ ${USE_CLANG_GCC} == true]; then
        GCC_32="CROSS_COMPILE_ARM32=arm-linux-gnueabi-"
    else
        if [ ${USE_GCC_TAG} = true ]; then
            if [ -f "$WORKSPACE/kernel_workspace/gcc-${GCC_TAG}-32.tar.gz" ]; then
                if [ -d "$WORKSPACE/kernel_workspace/gcc-32" ]; then
                    echo "GCC-ARM32 already exists."
                else
                    mkdir gcc-32
                    tar -C gcc-32/ -zxvf gcc-${GCC_TAG}-32.tar.gz
                fi
            else
                if [ -d "$WORKSPACE/kernel_workspace/gcc-32" ]; then
                    rm -rf $WORKSPACE/kernel_workspace/gcc-32
                fi
                mkdir gcc-32
                wget -O gcc-${GCC_TAG}-32.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/${GCC_TAG}.tar.gz
                tar -C gcc-32/ -zxvf gcc-${GCC_TAG}-32.tar.gz
            fi
        fi
        if [ ${USE_GCC_COMMIT_ID} = true ]; then
            if [ -f "$WORKSPACE/kernel_workspace/gcc-${GCC_COMMIT_ID}-32.tar.gz" ]; then
                if [ -d "$WORKSPACE/kernel_workspace/gcc-32" ]; then
                    echo "GCC-ARM64 already exists."
                else
                    mkdir gcc-32
                    tar -C gcc-32/ -zxvf gcc-${GCC_COMMIT_ID}-32.tar.gz
                fi
            else
                if [ -d "$WORKSPACE/kernel_workspace/gcc-32" ]; then
                    rm -rf $WORKSPACE/kernel_workspace/gcc-32
                fi
                mkdir gcc-32
                wget -O gcc-${GCC_COMMIT_ID}-32.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/${GCC_COMMIT_ID}.tar.gz
                tar -C gcc-32/ -zxvf gcc-${GCC_COMMIT_ID}-32.tar.gz
            fi
        fi
        GCC_32="CROSS_COMPILE_ARM32=$WORKSPACE/kernel_workspace/gcc-32/bin/arm-linux-androideabi-"
    fi
fi

# Download mkbootimg tools
if [ ${BUILD_BOOT_IMG} == true ]; then
    cd $WORKSPACE/kernel_workspace
    git clone https://android.googlesource.com/platform/system/tools/mkbootimg tools -b master-kernel-build-2022 --depth=1
fi

# Download kernel source
if [ ${DOWNLOAD_KERNEL_SOURCE} == true ]; then
    cd $WORKSPACE/kernel_workspace
    if [ -d "android-kernel" ]; then
        rm -rf android-kernel
    fi
    git clone ${KERNEL_SOURCE} -b ${KERNEL_SOURCE_BRANCH} android-kernel --depth=1
fi

# Download source boot image
if [ ${BUILD_BOOT_IMG} == true ]; then
    cd $WORKSPACE/kernel_workspace
    wget -O boot-source.img ${SOURCE_BOOT_IMAGE}
    if [ -f boot-source.img ]; then
        FORMAT_MKBOOTING=$(echo $(tools/unpack_bootimg.py --boot_img=boot-source.img --format mkbootimg))
        HAVE_SOURCE_BOOT_IMAGE=true
    fi
fi

# Setup KernelSU
if [ ${ENABLE_KERNELSU} == true ]; then
    cd $WORKSPACE/kernel_workspace/android-kernel
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s ${KERNELSU_TAG}
    UPLOADNAME=-KernelSU
fi

# Setup Configuration for Kernel
cd $WORKSPACE/kernel_workspace/android-kernel
if [ ${ADD_KPROBES_CONFIG} = true ]; then
    echo "CONFIG_MODULES=y" >>arch/${ARCH}/configs/${KERNEL_CONFIG}
    echo "CONFIG_KPROBES=y" >>arch/${ARCH}/configs/${KERNEL_CONFIG}
    echo "CONFIG_HAVE_KPROBES=y" >>arch/${ARCH}/configs/${KERNEL_CONFIG}
    echo "CONFIG_KPROBE_EVENTS=y" >>arch/${ARCH}/configs/${KERNEL_CONFIG}
fi
if [ ${ADD_OVERLAYFS_CONFIG} = true ]; then
    echo "CONFIG_OVERLAY_FS=y" >>arch/${ARCH}/configs/${KERNEL_CONFIG}
fi
if [ ${DISABLE_LTO} = true ]; then
    sed -i 's/CONFIG_LTO=y/CONFIG_LTO=n/' arch/${ARCH}/configs/${KERNEL_CONFIG}
    sed -i 's/CONFIG_LTO_CLANG=y/CONFIG_LTO_CLANG=n/' arch/${ARCH}/configs/${KERNEL_CONFIG}
    sed -i 's/CONFIG_THINLTO=y/CONFIG_THINLTO=n/' arch/${ARCH}/configs/${KERNEL_CONFIG}
    echo "CONFIG_LTO_NONE=y" >>arch/${ARCH}/configs/${KERNEL_CONFIG}
fi
if [ ${DISABLE_CC_WERROR} = true ]; then
    echo "CONFIG_CC_WERROR=n" >>arch/${ARCH}/configs/${KERNEL_CONFIG}
fi

# Setup ccache
# if [ ${ENABLE_CCACHE} == true ]; then
# export set CC='ccache gcc'
# build-kernel-${DEVICE}${UPLOADNAME}max-size: 2G
# fi

# Build kernel
cd $WORKSPACE/kernel_workspace/android-kernel
export PATH=$WORKSPACE/kernel_workspace/clang-aosp/bin:$PATH
export KBUILD_BUILD_HOST=LocalHost
export KBUILD_BUILD_USER=$(echo ${Actor} | tr A-Z a-z)
if [ ! -z ${KSU_EXPECTED_SIZE} ] && [ ! -z ${KSU_EXPECTED_HASH} ]; then
    export KSU_EXPECTED_SIZE=${KSU_EXPECTED_SIZE}
    export KSU_EXPECTED_HASH=${KSU_EXPECTED_HASH}
fi
make -j$(nproc --all) CC=clang O=out ARCH=${ARCH} ${CUSTOM_CMDS} ${EXTRA_CMDS} ${GCC_64} ${GCC_32} ${KERNEL_CONFIG} 2>&1 | tee ${WORKSPACE}/kernel.log
if [ ${ENABLE_CCACHE} = true ]; then
    make -j$(nproc --all) CC="ccache clang" O=out ARCH=${ARCH} ${CUSTOM_CMDS} ${EXTRA_CMDS} ${GCC_64} ${GCC_32} 2>&1 | tee ${WORKSPACE}/kernel.log
else
    make -j$(nproc --all) CC=clang O=out ARCH=${ARCH} ${CUSTOM_CMDS} ${EXTRA_CMDS} ${GCC_64} ${GCC_32} 2>&1 | tee ${WORKSPACE}/kernel.log
fi

# Check a kernel output files
cd $WORKSPACE/kernel_workspace
if [ -f android-kernel/out/arch/${ARCH}/boot/${KERNEL_IMAGE_NAME} ]; then
    CHECK_FILE_IS_OK=true
else
    echo "Kernel output file is empty"
    exit 1
fi
if [ ${NEED_DTBO} = true ]; then
    if [ -f android-kernel/out/arch/${ARCH}/boot/dtbo.img ]; then
        CHECK_DTBO_IS_OK=true
    else
        echo "DTBO image is empty"
        exit 1
    fi
fi

# Make Anykernel3
if [ ${CHECK_FILE_IS_OK} == true ]; then
    cd $WORKSPACE/kernel_workspace
    git clone https://github.com/osm0sis/AnyKernel3
    sed -i 's/device.name1=maguro/device.name1=${ANYKERNEL_DEVICE_NAME_1}/g' AnyKernel3/anykernel.sh
    sed -i 's/device.name2=maguro/device.name2=${ANYKERNEL_DEVICE_NAME_2}/g' AnyKernel3/anykernel.sh
    sed -i 's/device.name3=maguro/device.name3=${ANYKERNEL_DEVICE_NAME_3}/g' AnyKernel3/anykernel.sh
    sed -i 's/device.name4=maguro/device.name4=${ANYKERNEL_DEVICE_NAME_4}/g' AnyKernel3/anykernel.sh
    sed -i 's/device.name5=maguro/device.name5=${ANYKERNEL_DEVICE_NAME_5}/g' AnyKernel3/anykernel.sh
    sed -i 's!block=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!block=${ANYKERNEL_BLOCK};!g' AnyKernel3/anykernel.sh
    sed -i 's/is_slot_device=0;/is_slot_device=${ANYKERNEL_IS_SLOT_DEVICE};/g' AnyKernel3/anykernel.sh
    cp android-kernel/out/arch/${ARCH}/boot/${KERNEL_IMAGE_NAME} AnyKernel3/
    if [ ${CHECK_DTBO_IS_OK} = true ]; then
        cp android-kernel/out/arch/${ARCH}/boot/dtbo.img AnyKernel3/
    fi
    rm -rf AnyKernel3/.git* AnyKernel3/README.md
fi

# Make boot image
if [ ${HAVE_SOURCE_BOOT_IMAGE} == true ] && [ ${CHECK_FILE_IS_OK} == true ]; then
    cd $WORKSPACE/kernel_workspace
    tools/unpack_bootimg.py --boot_img boot-source.img
    cp android-kernel/out/arch/${ARCH}/boot/${KERNEL_IMAGE_NAME} out/kernel
    tools/mkbootimg.py ${FORMAT_MKBOOTING} -o boot.img
    if [ -f boot.img ]; then
        MAKE_BOOT_IMAGE_IS_OK=true
    else
        echo "Boot image is empty"
        exit 1
    fi
fi
