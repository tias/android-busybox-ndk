Building busybox with the standard android NDK
----------------------------------------------

The aim is to gather information and patches on how to build busybox using the compiler shipped with the android NDK.

I recently discovered that a number [[1](http://lists.busybox.net/pipermail/busybox/2012-March/077486.html),[2](http://lists.busybox.net/pipermail/busybox/2012-March/077505.html)] of upstream changes make it possible to build the latest git version of busybox, __without requiring any patches__:

    # get busybox sources
    git clone git://busybox.net/busybox.git
    # use default upstream config
    cp configs/android_ndk_defconfig .config
    
    # add arm-linux-androideabi-* to your PATH
    export PATH="$PATH:/path/to/your/android-ndk/android-ndk-r7b/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin/"
    # if android-ndk is not installed in /opt/android-ndk, edit SYSROOT= in .config
    xdg-open .config
    
    # build it!
    make
