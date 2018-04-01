The aim is to gather information and patches on how to build busybox using the compilers shipped with the Android NDK.

Currently up-to-date as of busybox 1.28.2, with added patches to avoid constant host warnings if compiling in Cygwin.

Building busybox with the standard Android NDK
==============================================

tias@ulyssis.org discovered that a number [[1](http://lists.busybox.net/pipermail/busybox/2012-March/077486.html),[2](http://lists.busybox.net/pipermail/busybox/2012-March/077505.html)] of upstream changes make it possible to build the latest git version of busybox, **without requiring any patches**:

    # get busybox sources
    git clone git://busybox.net/busybox.git
    # use default upstream config
    cp configs/android_ndk_defconfig .config
    
    # add the target NDK cross-compiler to your exported PATH and CROSS_COMPILE prefix
    export PATH="/path/to/your/android-ndk/android-ndk-r7b/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin:$PATH"
    export CROSS_COMPILE="/path/to/your/android-ndk/android-ndk-r7b/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin/arm-linux-androideabi-"
    
    # if android-ndk is not installed in /opt/android-ndk, edit SYSROOT= in .config
    # (alternately make all but CFLAGS blank if using standalone cross-compiler)
    nano .config
    
    # adjust enabled applets/features (optional)
    make menuconfig
    
    # build it!
    make ARCH=arm CROSS_COMPILE="$CROSS_COMPILE"

**NOTE:** Currently there is no way to compile busybox on Android NDK API <21 without changes due to a [compatibility issue](https://bugs.busybox.net/show_bug.cgi?id=10791) introduced with the run-init applet, but it can be worked around easily by reverting the run-init commits as follows:

    git revert --no-edit 7d834c9bb436edd594ebacc48d2b9ea7d3364dbd bbc26c6934fac218e19c7897f2dc2e6084e963b0 200bcc851acbe1ba30fe90b5cf918f88370a5d15

These applets are available without any patches:
> [, [[, acpid, adjtimex, ar, arp, ash, awk, base64, basename, bbconfig, beep, blkid, blockdev, bootchartd, brctl, bunzip2, bzcat, bzip2, cal, cat, catv, chat, chattr, chgrp, chmod, chown, chpst, chroot, chrt, chvt, cksum, clear, cmp, comm, cp, cpio, crond, crontab, cttyhack, cut, date, dc, dd, deallocvt, depmod, devmem, diff, dirname, dmesg, dnsd, dnsdomainname, dos2unix, dpkg, dpkg-deb, du, dumpkmap, echo, ed, egrep, env, envdir, envuidgid, expand, expr, factor, fakeidentd, false, fbset, fbsplash, fdflush, fdformat, fdisk, fgconsole, fgrep, find, findfs, flash\_lock, flash\_unlock, flashcp, flock, fold, free, freeramdisk, fsfreeze, fsync, ftpd, ftpget, ftpput, fuser, getopt, grep, groups, gunzip, gzip, halt, hd, hdparm, head, hexdump, hostname, httpd, hwclock, id, ifconfig, ifdown, ifup, inetd, init, inotifyd, insmod, install, ionice, iostat, ip, ipaddr, ipcalc, iplink, iptunnel, kbd\_mode, kill, killall, killall5, klogd, less, link, linuxrc, ln, loadkmap, losetup, lpd, lpq, lpr, ls, lsattr, lsmod, lspci, lsscsi, lsusb, lzcat, lzma, lzop, lzopcat, makedevs, makemime, man, md5sum, mesg, mkdir, mkdosfs, mkfifo, mkfs.vfat, mknod, mkswap, mktemp, modinfo, modprobe, more, mpstat, mv, nbd-client, nc, netstat, nice, nl, nmeter, nohup, od, openvt, partprobe, paste, patch, pidof, ping, pipe\_progress, pivot\_root, pkill, pmap, popmaildir, poweroff, powertop, printenv, printf, ps, pscan, pstree, pwd, pwdx, raidautorun, rdate, rdev, readlink, readprofile, realpath, reboot, reformime, renice, reset, resize, rev, rm, rmdir, rmmod, route, rpm, rpm2cpio, rtcwake, run-parts, runsv, runsvdir, rx, script, scriptreplay, sed, sendmail, seq, setconsole, setkeycodes, setlogcons, setpriv (without capabilities), setserial, setsid, setuidgid, sh, sha1sum, sha256sum, sha512sum, showkey, shred, slattach, sleep, smemcap, softlimit, sort, split, ssl_client, start-stop-daemon, stat, strings, stty, sum, sv, svc, svlogd, sync, sysctl, tac, tail, tar, tcpsvd, tee, test, tftp, tftpd, timeout, top, touch, tr, traceroute, true, tty, ttysize, tunctl, tune2fs, udhcpc, udpsvd, uname, uncompress, unexpand, uniq, unix2dos, unlzma, unlzop, unxz, unzip, uptime, usleep, uudecode, uuencode, vconfig, vi, volname, watch, wc, wget, which, whoami, whois, xargs, xxd, xz, xzcat, yes, zcat

By **applying the included patches** to the busybox code-base you additionally get:
> arping, blkdiscard, conspy, df, eject, ether-wake, fsck, fsck.minix, hush, ifenslave, ifplugd, ipcrm, ipcs, ipneigh, iproute, iprule, loadfont, logread, microcom, mke2fs, mkfs.ext2, mkfs.minix, mkfs.reiser, mount, mountpoint, nanddump, nandwrite, nameif, nslookup (with own resolver), pgrep, ping6, rfkill, run-init, setfont, swapon, swapoff, switch\_root, syslogd, telnet, telnetd, time, traceroute6, ubi*, udhcpc6, udhcpd, umount, watchdog, zcip

Also worth noting that while they do build without issue these applets do not work correctly on Android without any patches:
> poweroff, reboot

(when applying certain patches you should include all patches with a lower number as well, there are often dependencies between them).

The **remaining config options** of 'make defconfig' do not build properly. See below for the list of config options and corresponding error.

Config options that do not build, code error
--------------------------------------------
These errors indicate bugs (usually in the restricted Android libc library, called bionic), and can often be fixed by adding patches to the busybox code.

* All of *Login/Password Management Utilities*, CONFIG\_USE\_BB\_PWD\_GRP  --  error: 'struct passwd' has no member named 'pw_gecos'
  * disables CONFIG\_ADD\_SHELL, CONFIG\_REMOVE\_SHELL, CONFIG\_ADDUSER, CONFIG\_ADDGROUP, CONFIG\_DELUSER, CONFIG\_DELGROUP, CONFIG\_GETTY, CONFIG\_LOGIN, CONFIG\_PASSWD, CONFIG\_CRYPTPW, CONFIG\_CHPASSWD, CONFIG\_MKPASSWD, CONFIG\_SU, CONFIG\_SULOGIN, CONFIG\_VLOCK
* CONFIG\_ARPING  --  **has patch**  --  networking/arping.c:96: error: invalid use of undefined type 'struct arphdr'
* CONFIG\_BLKDISCARD  --  **has patch**  --  util-linux/blkdiscard.c:72:26: error: 'BLKSECDISCARD' undeclared (first use in this function)
* CONFIG\_ETHER\_WAKE  --  **has patch**  --  networking/ether-wake.c:275: error: 'ETH_ALEN' undeclared (first use in this function)
* CONFIG\_FEATURE\_IP\_ROUTE, CONFIG\_FEATURE\_IP\_RULE, CONFIG\_IP\_ROUTE, CONFIG\_IPRULE  --  **has patch**  --  networking/libiproute/iproute.c:85:9: error: 'RTA_TABLE' undeclared (first use in this function)
* CONFIG\_FEATURE\_IPV6  --  **has patch**    --  networking/ifconfig.c:82: error: redefinition of 'struct in6_ifreq'
  * disables CONFIG\_PING6, CONFIG\_FEATURE\_IFUPDOWN\_IPV6, CONFIG\_TRACEROUTE6
* CONFIG\_FEATURE\_UTMP, CONFIG\_FEATURE\_WTMP  --  init/halt.c:86: error: 'RUN_LVL' undeclared (first use in this function)
  * disables CONFIG\_WHO, CONFIG\_USERS, CONFIG\_LAST, CONFIG\_RUNLEVEL, CONFIG\_WALL
* CONFIG\_FSCK\_MINIX, CONFIG\_MKFS\_MINIX  --  **has patch**  --  util-linux/fsck\_minix.c:111: error: 'INODE_SIZE1' undeclared here (not in a function)
* CONFIG\_LFS  --  **[on purpose?](http://lists.busybox.net/pipermail/busybox-cvs/2011-November/033019.html)**  --  **has patch (experimental)**  --  include/libbb.h:256: error: size of array 'BUG_off_t_size_is_misdetected' is negative
* CONFIG\_LOGGER  --  sysklogd/logger.c:36: error: expected ';', ',' or ')' before '*' token
* CONFIG\_NANDDUMP, CONFIG\_NANDWRITE  --  **has patch**  --  miscutils/nandwrite.c:151:35: error: 'MTD_FILE_MODE_RAW' undeclared (first use in this function)
* CONFIG\_NSLOOKUP  -- **has patch (with own resolver)**  --  networking/nslookup.c:126: error: dereferencing pointer to incomplete type
* **CONFIG\_PLATFORM\_LINUX**  --  **has patch**  --  libbb/capability.c:94:3: error: '_LINUX_CAPABILITY_U32S_3' undeclared (first use in this function)
* CONFIG\_RUN\_INIT  --  **has patch**  --  util-linux/switch_root.c:121:14: error: 'PR_CAPBSET_READ' undeclared (first use in this function)
* CONFIG\_SWAPOFF, CONFIG\_SWAPON  --  **has patch**  --  util-linux/swaponoff.c:96: error: 'MNTOPT_NOAUTO' undeclared (first use in this function)
* CONFIG\_TLS  --  **has patch**  --  networking/tls\_pstm\_montgomery\_reduce.c:66:1: error: 'asm' operand has impossible constraints
* CONFIG\_ZCIP  --  **has patch**  --  networking/zcip.c:51: error: field 'arp' has incomplete type

Config options that do not build, missing library
-------------------------------------------------
These errors indicate that the library is missing from Android's libc implementation.

sys/sem.h  --  **has patch**
* CONFIG\_IPCS  --  util-linux/ipcs.c:32:21: error: sys/sem.h: No such file or directory
* CONFIG\_LOGREAD  --  sysklogd/logread.c:20:21: error: sys/sem.h: No such file or directory
* CONFIG\_SYSLOGD  --  sysklogd/syslogd.c:68:21: error: sys/sem.h: No such file or directory

sys/kd.h  --  **has patch**
* CONFIG\_CONSPY  --  miscutils/conspy.c:45:20: error: sys/kd.h: No such file or directory
* CONFIG\_LOADFONT, CONFIG\_SETFONT  --  console-tools/loadfont.c:33:20: error: sys/kd.h: No such file or directory

arpa/telnet.h  --  **has patch**
* CONFIG\_TELNET  --  networking/telnet.c:39:25: error: arpa/telnet.h: No such file or directory
* CONFIG\_TELNETD  --  networking/telnetd.c:53:25: error: arpa/telnet.h: No such file or directory

others
* CONFIG\_DF  --  **has patch**  --  coreutils/df.c:80:25: error: sys/statvfs.h: No such file or directory
* CONFIG\_EJECT  --  **has patch**  --  miscutils/eject.c:30:21: error: scsi/sg.h: No such file or directory
* CONFIG\_FEATURE\_HAVE\_RPC, CONFIG\_FEATURE\_INETD\_RPC  --  networking/inetd.c:176:22: error: rpc/rpc.h: No such file or directory
* CONFIG\_FEATURE\_IFCONFIG\_SLIP  -- **has patch**  --  networking/ifconfig.c:59:26: error: net/if\_slip.h: No such file or directory
* CONFIG\_FEATURE\_SHADOWPASSWDS  --  include/libbb.h:61:22: error: shadow.h: No such file or directory
  * CONFIG\_USE\_BB\_PWD\_GRP, CONFIG\_USE\_BB\_SHADOW would potentially work around, but there is a code error as listed above
* CONFIG\_HUSH  --  **has patch**  --  shell/hush.c:89:18: error: glob.h: No such file or directory
* CONFIG\_I2C*  --  miscutils/i2c\_tools.c:65:27: error: linux/i2c-dev.h: No such file or directory
  * disables CONFIG\_I2CGET, CONFIG\_I2CSET, CONFIG\_I2CDUMP, CONFIG\_I2CDETECT
* CONFIG\_IFENSLAVE  --  **has patch**  --  networking/ifenslave.c:132:30: error: linux/if\_bonding.h: No such file or directory
* CONFIG\_IFPLUGD  --  **has patch**  --  networking/ifplugd.c:38:23: error: linux/mii.h: No such file or directory
* CONFIG\_IPCRM  --  **has patch**  --  util-linux/ipcrm.c:25:21: error: sys/shm.h: No such file or directory
* CONFIG\_IPNEIGH -- **has patch**  --  networking/libiproute/ipneigh.c:14:29: error: linux/neighbour.h: No such file or directory
* CONFIG\_LINUX32, CONFIG_LINUX64, CONFIG\_SETARCH  --  util-linux/setarch.c:23:29: error: sys/personality.h: No such file or directory
* CONFIG\_MT  --  miscutils/mt.c:19:22: error: sys/mtio.h: No such file or directory
* CONFIG\_NTPD  --  networking/ntpd.c:49:23: error: sys/timex.h: No such file or directory
* CONFIG\_RFKILL  --  **has patch**  --  miscutils/rfkill.c:40:26: error: linux/rfkill.h: No such file or directory
* CONFIG\_SETFATTR  --  miscutils/setfattr.c:18:23: error: sys/xattr.h: No such file or directory
* CONFIG\_WATCHDOG  --  **has patch**  --  miscutils/watchdog.c:24:28: error: linux/watchdog.h: No such file or directory
* CONFIG\_UDHCPC6  --  **has patch**  --  networking/udhcp/d6\_socket.c:10:21: error: ifaddrs.h: No such file or directory
* CONFIG\_UBI*  --  **has patch**  --  miscutils/ubi\_tools.c:67:26: error: mtd/ubi-user.h: No such file or directory
  * disables CONFIG\_UBIATTACH, CONFIG\_UBIDETACH, CONFIG\_UBIMKVOL, CONFIG\_UBIRMVOL, CONFIG\_UBIRSVOL, CONFIG\_UBIUPDATEVOL, CONFIG\_UBIRENAME

Config options that give a linking error
----------------------------------------
Android's libc implementation claims to implement the methods in the error, but surprisingly does not.

mntent -- **has patch**
 * CONFIG\_DF  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_FSCK  --  undefined reference to 'setmntent', 'getmntent\_r', 'endmntent'
 * CONFIG\_MKE2FS  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_MKFS\_EXT2  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_MKFS\_REISER  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_MOUNTPOINT  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_MOUNT  --  undefined reference to 'setmntent', 'getmntent\_r'
 * CONFIG\_UMOUNT  --  undefined reference to 'setmntent', 'getmntent\_r', 'endmntent'

others
 * CONFIG\_FALLOCATE  --  undefined reference to 'posix\_fallocate'
 * CONFIG\_FEATURE\_HTTPD\_AUTH\_MD5  --  undefined reference to 'crypt'
 * CONFIG\_FEATURE\_SYNC\_FANCY  --   undefined reference to 'syncfs'
 * CONFIG\_HOSTID  --  undefined reference to 'gethostid'
 * CONFIG\_LOGNAME  --  undefined reference to 'getlogin\_r'
 * CONFIG\_MDEV  --  undefined reference to 'sigtimedwait'
 * CONFIG\_MICROCOM  --  **has patch**  --  undefined reference to 'cfsetspeed'
 * CONFIG\_NAMEIF  --  **has patch**  --  undefined reference to 'ether\_aton\_r'
 * CONFIG\_NPROC  -- undefined reference to 'sched\_getaffinity'
 * CONFIG\_NSENTER  --  undefined reference to 'setns'
 * CONFIG\_SETFATTR  --  undefined reference to 'removexattr', 'lremovexattr', 'lsetxattr', 'setxattr'
 * CONFIG\_TIME  -- **has patch**  --  undefined reference to 'wait3'
 * CONFIG\_UDHCPC6  --  **has patch**  --  undefined reference to 'getifaddrs', 'freeifaddrs'
 * CONFIG\_UDHCPD  --  **has patch**  --  undefined reference to 'ether\_aton\_r'
 * CONFIG\_UNSHARE  --  undefined reference to 'unshare'
