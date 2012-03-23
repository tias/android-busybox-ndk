# Makefile for android-busybox-ndk
# fetches upstream busybox from git, applies patches, builds it

# Point to your android-ndk installation
ANDROID_NDK="/opt/android-ndk"

# Config to use
CONFIG_FILE="./android_ndk_stericson-like"
#CONFIG_FILE="android_ndk_config-w-patches" # contains more


# Following options should not be changed unless you know better
BB_DIR="busybox-git"
SYSROOT="$(ANDROID_NDK)/platforms/android-9/arch-arm"
GCC_PREFIX="$(ANDROID_NDK)/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin/arm-linux-androideabi-"


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
	cat $(CONFIG_FILE) | \
		sed "s|\(CONFIG_CROSS_COMPILER_PREFIX=\).*|\1\"$(GCC_PREFIX)\"|" | \
		sed "s|\(CONFIG_SYSROOT=\).*|\1\"$(SYSROOT)\"|" \
		> $(BB_DIR)/.config

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
