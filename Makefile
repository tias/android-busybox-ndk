# Makefile for android-busybox-ndk
# fetches upstream busybox from git, applies patches, builds it

# Point to your android-ndk installation
ANDROID_NDK="/opt/android-ndk"

# Pick your target ARCH (arm,mips,x86)
ARCH=x86

# Config to use
CONFIG_FILE="./android_ndk_stericson-like"
#CONFIG_FILE="android_ndk_config-w-patches" # contains more


# Following options should not be changed unless you know better
BB_DIR="busybox-git.$(ARCH)"
SYSROOT="$(ANDROID_NDK)/platforms/android-14/arch-$(ARCH)"

#
# ARM SETUP
#
ifeq ($(ARCH),arm)
  GCC_PREFIX=$(ANDROID_NDK)/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin/arm-linux-androideabi-
  EXTRA_CFLAGS=-DANDROID -D__ANDROID__ -DSK_RELEASE -nostdlib -march=armv7-a -msoft-float -mfloat-abi=softfp -mfpu=neon -mthumb -mthumb-interwork -fpic -fno-short-enums -fgcse-after-reload -frename-registers
  EXTRA_LDFLAGS=-Xlinker -z -Xlinker muldefs -nostdlib -Bdynamic -Xlinker -dynamic-linker -Xlinker /system/bin/linker -Xlinker -z -Xlinker nocopyreloc -Xlinker --no-undefined \$${SYSROOT}/usr/lib/crtbegin_dynamic.o \$${SYSROOT}/usr/lib/crtend_android.o
endif

#
# MIPS SETUP
# NOTE: MIPS_SIM_NABI32  is a 64bit ABI; Android uses MIPS_SIM_ABI32
#
ifeq ($(ARCH),mips)
  GCC_PREFIX=$(ANDROID_NDK)/toolchains/mipsel-linux-android-4.4.3/prebuilt/linux-x86/bin/mipsel-linux-android-
  EXTRA_CFLAGS=-DANDROID -D__ANDROID__ -DSK_RELEASE -fpic -fno-short-enums -fgcse-after-reload -frename-registers  -U_MIPS_SIM -D_MIPS_SIM=_MIPS_SIM_ABI32
  EXTRA_LDFLAGS=-Xlinker -z -Xlinker muldefs -nostdlib -Bdynamic -Xlinker -dynamic-linker -Xlinker /system/bin/linker -Xlinker -z -Xlinker nocopyreloc -Xlinker --no-undefined \$${SYSROOT}/usr/lib/crtbegin_dynamic.o \$${SYSROOT}/usr/lib/crtend_android.o
endif

#
# X86 SETUP
#
ifeq ($(ARCH),x86)
  GCC_PREFIX=$(ANDROID_NDK)/toolchains/x86-4.4.3/prebuilt/linux-x86/bin/i686-android-linux-
  EXTRA_CFLAGS=-DANDROID -D__ANDROID__ -DSK_RELEASE -nostdlib -fpic -fno-short-enums -fgcse-after-reload -frename-registers -Dhtons=__swap16 -Dhtonl=__swap32 -Dntohs=__swap16 -Dntohl=__swap32 -D_XOPEN_SOURCE -D_POSIX_C_SOURCE
  EXTRA_LDFLAGS=-Xlinker -z -Xlinker muldefs -nostdlib -Bdynamic -Xlinker -dynamic-linker -Xlinker /system/bin/linker -Xlinker -z -Xlinker nocopyreloc -Xlinker --no-undefined \$${SYSROOT}/usr/lib/crtbegin_dynamic.o \$${SYSROOT}/usr/lib/crtend_android.o
endif


all: busybox-git config patches build

busybox-git:
	if test -d $(BB_DIR); then \
		echo "'$(BB_DIR)' already exists"; \
	else \
		echo "Fetching fresh busybox source"; \
		git clone git://git.busybox.net/busybox $(BB_DIR); \
	fi

config:
	if test ! -f $(CONFIG_FILE); then \
		echo "Error: config file '$(CONFIG_FILE)' does not exist!" \
		exit 1; \
	fi

patches:
	if test -f $(BB_DIR)/android-busybox-ndk-patched; then \
		echo "Busybox already patched"; \
	else \
		echo "Applying patches"; \
		for i in patches/*.patch; do \
			patch -d $(BB_DIR) --forward -p1 < $$i; \
		done; \
		touch "$(BB_DIR)/android-busybox-ndk-patched"; \
	fi
	@echo "EXPORT CONFIG_FILE=$(CONFIG_FILE)"
	@echo "EXPORT GCC_PREFIX=$(GCC_PREFIX)"
	@echo "EXPORT SYSROOT=$(SYSROOT)"
	@echo "EXPORT EXTRA_CFLAGS=$(EXTRA_CFLAGS)"
	@echo "EXPORT EXTRA_LDFLAGS=$(EXTRA_LDFLAGS)"
	cat $(CONFIG_FILE) | \
		sed "s%\(CONFIG_CROSS_COMPILER_PREFIX=\).*%\1\"$(GCC_PREFIX)\"%" | \
                sed "s%\(CONFIG_SYSROOT=\).*%\1\"$(SYSROOT)\"%" | \
		sed "s%\(CONFIG_EXTRA_CFLAGS=\).*%\1\"$(EXTRA_CFLAGS)\"%" | \
		sed "s%\(CONFIG_EXTRA_LDFLAGS=\).*%\1\"$(EXTRA_LDFLAGS)\"%" \
		> $(BB_DIR)/.config
build-check:
	if test ! -d $(ANDROID_NDK); then \
		echo "Error: edit 'Makefile' and point 'ANDROID_NDK=' to your android ndk installation\n(currently: $(ANDROID_NDK))"; exit 1; \
	fi
	if test ! -d $(SYSROOT); then \
		echo "Error: can not find 'android-9' platform in '$(SYSROOT)', did you install it?"; exit 1; \
	fi
	if test ! -f $(GCC_PREFIX)gcc; then \
		echo "Error: can not find crosscompiler with prefix $(GCC_PREFIX), did you install it?"; exit 1; \
	fi

build: build-check
	make -C $(BB_DIR)
	echo "Busybox binary at '$(BB_DIR)/busybox'"


clean:
	make -C $(BB_DIR) clean
	# undo patches
	cd $(BB_DIR) && git checkout . && git clean -f -d

dist-clean: distclean
distclean:
	rm -Rf $(BB_DIR)

.PHONY: busybox-git patches
