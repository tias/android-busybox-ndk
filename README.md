The aim is to gather information and patches on how to build busybox using the compiler shipped with the android NDK.

Patches and relevant pointers more than welcome, fork me or mail me: tias-@-ulyssis.org

Building busybox with the standard android NDK
==============================================

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

This creates a busybox with the following applets:
> [, [[, ar, arp, awk, base64, basename, beep, blkid, blockdev, bootchartd, bunzip2, bzcat, bzip2, cal, cat, catv, chat, chattr, chgrp, chmod, chown, chpst, chroot, chrt, chvt, cksum, clear, cmp, comm, cp, cpio, crond, crontab, cttyhack, cut, dc, dd, deallocvt, depmod, devmem, diff, dirname, dmesg, dnsd, dos2unix, dpkg, dpkg-deb, du, dumpkmap, echo, ed, egrep, env, envdir, envuidgid, expand, expr, fakeidentd, false, fbset, fbsplash, fdflush, fdformat, fdisk, fgconsole, fgrep, find, findfs, flash\_lock, flash\_unlock, flashcp, flock, fold, free, freeramdisk, fsync, ftpd, ftpget, ftpput, fuser, getopt, grep, gunzip, gzip, halt, hd, hdparm, head, hexdump, httpd, hwclock, ifconfig, ifdown, ifup, init, inotifyd, insmod, install, iostat, ip, ipaddr, ipcalc, iplink, iproute, iprule, iptunnel, klogd, less, linuxrc, ln, loadkmap, losetup, lpd, lpq, lpr, ls, lsattr, lsmod, lspci, lsusb, lzcat, lzma, lzop, lzopcat, makedevs, makemime, man, md5sum, mdev, mesg, mkdir, mkfifo, mknod, mkswap, mktemp, modinfo, modprobe, more, mpstat, mv, nbd-client, nc, netstat, nice, nmeter, nohup, od, openvt, patch, pidof, ping, pipe\_progress, pmap, popmaildir, poweroff, powertop, printenv, printf, ps, pscan, pstree, pwd, pwdx, raidautorun, rdev, readlink, readprofile, realpath, reboot, reformime, renice, reset, resize, rev, rm, rmdir, rmmod, route, rpm, rpm2cpio, rtcwake, run-parts, runsv, runsvdir, rx, script, scriptreplay, sed, sendmail, seq, setconsole, setkeycodes, setlogcons, setserial, setsid, setuidgid, sha1sum, sha256sum, sha512sum, showkey, sleep, smemcap, softlimit, sort, split, start-stop-daemon, strings, stty, sum, sv, svlogd, switch\_root, sync, sysctl, tac, tail, tar, tcpsvd, tee, telnet, telnetd, test, tftp, tftpd, time, timeout, top, touch, tr, traceroute, true, ttysize, tunctl, tune2fs, udhcpc, udpsvd, uname, uncompress, unexpand, uniq, unix2dos, unlzma, unlzop, unxz, unzip, uptime, usleep, uudecode, uuencode, vconfig, vi, volname, watch, wc, wget, which, whoami, whois, xargs, xz, xzcat, yes, zcat

Using file *android\_ndk\_defconfigPlus* you additionally get following applets that are by default enabled for 'make defconfig':
> acpid, ash, groups, id, mkdosfs, mkfs.vfat, nandump, nandwrite, sh, slattach, tty

By **applying the included patches** to the busybox code-base (and config *android\_ndk\_config-w-patches*), you additionally get:
> adjtimex, arping, bbconfig, brctl, date, df, ether-wake, fsck, fsck.minix, hostname, hush, inetd, ionice, ipcrm, ipcs, kbd\_mode, kill, killall, killall5, logread, microcom, mke2fs, mkfs.ext2, mkfs.minix, mkfs.reiser, mount, mountpoint, nameif, nslookup (with own resolver), pgrep, ping6, pivot_root, pkill, rdate, stat, swapon, swapoff, syslogd, traceroute6, ubi*, udhcpd, umount, watchdog, zcip

(when cherry-picking certain patches you have to include all patches with a lower number as well, there are dependencies between them except for 050 and 051).


The **remaining config options** of 'make defconfig' do not build properly. See below for the list of config options and corresponding error.

The config *android\_ndk\_stericson-like* is a config similar to the one shipped by android-busybox (by stericson). You can download a [binary](https://github.com/downloads/tias/android-busybox-ndk/busybox-ndk-cc1bb603e) built with this config (md5sum ab9f5cd5032af9fa7c20c2e9d0ec047d).

Config options that do not build, code error
--------------------------------------------
These errors indicate bugs (usually in the restricted android libc library, called bionic), and can often be fixed by adding patches to the busybox code.

* All of *Login/Password Management Utilities*  --  error: 'struct passwd' has no member named 'pw\_gecos'
 * disables CONFIG\_ADD\_SHELL, CONFIG\_REMOVE\_SHELL, CONFIG\_ADDUSER, CONFIG\_ADDGROUP, CONFIG\_DELUSER, CONFIG\_DELGROUP, CONFIG\_GETTY, CONFIG\_LOGIN, CONFIG\_PASSWD, CONFIG\_CRYPTPW, CONFIG\_CHPASSWD, CONFIG\_SU, CONFIG\_SULOGIN, CONFIG\_VLOCK
* CONFIG\_ARPING  --  **has patch**  --  networking/arping.c:96: error: invalid use of undefined type 'struct arphdr'
* CONFIG\_BRCTL  --  **has patch**  --  networking/brctl.c:70: error: conflicting types for 'strtotimeval'
* CONFIG\_ETHER\_WAKE  --  **has patch**  --  networking/ether-wake.c:275: error: 'ETH_ALEN' undeclared (first use in this function)
* CONFIG\_FEATURE\_IPV6  --  **has patch**    --  networking/ifconfig.c:82: error: redefinition of 'struct in6\_ifreq'
 * disables CONFIG\_PING6, CONFIG\_FEATURE\_IFUPDOWN\_IPV6, CONFIG\_TRACEROUTE6
* CONFIG\_FEATURE\_UTMP, CONFIG\_FEATURE\_WTMP  --  init/halt.c:86: error: 'RUN_LVL' undeclared (first use in this function)
 * disables CONFIG\_WHO, CONFIG\_USERS, CONFIG\_LAST, CONFIG\_RUNLEVEL, CONFIG\_WALL
* CONFIG\_FSCK\_MINIX, CONFIG\_MKFS\_MINIX  --  **has patch**  --  util-linux/fsck\_minix.c:111: error: 'INODE\_SIZE1' undeclared here (not in a function)
* CONFIG\_INETD  --  **has patch**  --  /opt/android-ndk/platforms/android-9/arch-arm/usr/include/linux/un.h:18: error: expected specifier-qualifier-list before 'sa\_family\_t' and networking/inetd.c:562: error: 'struct sockaddr\_un' has no member named 'sun\_path'
* CONFIG\_IONICE  --  **has patch** -- miscutils/ionice.c:23: error: 'SYS\_ioprio\_set' undeclared (first use in this function)
* CONFIG\_LFS  --  **[on purpose?](http://lists.busybox.net/pipermail/busybox-cvs/2011-November/033019.html)**  --  include/libbb.h:256: error: size of array 'BUG\_off\_t\_size\_is\_misdetected' is negative
* CONFIG\_LOGGER  --  sysklogd/logger.c:36: error: expected ';', ',' or ')' before '*' token
* CONFIG\_NSLOOKUP  -- **has patch (with own resolver)**  --  networking/nslookup.c:126: error: dereferencing pointer to incomplete type
* CONFIG\_SWAPONOFF  --  **has patch**  --  util-linux/swaponoff.c:96: error: 'MNTOPT\_NOAUTO' undeclared (first use in this function)
* CONFIG\_ZCIP  --  **has patch**  --  networking/zcip.c:51: error: field 'arp' has incomplete type

Config options that do not build, missing library
-------------------------------------------------
These errors indicate that the library is missing from androids libc implementation

* sys/sem.h  **has patch**
 * CONFIG\_IPCS  --  util-linux/ipcs.c:32:21: error: sys/sem.h: No such file or directory
 * CONFIG\_LOGREAD  --  sysklogd/logread.c:20:21: error: sys/sem.h: No such file or directory
 * CONFIG\_SYSLOGD  --  sysklogd/syslogd.c:68:21: error: sys/sem.h: No such file or directory

* sys/kd.h
 * CONFIG\_CONSPY  --  miscutils/conspy.c:45:20: error: sys/kd.h: No such file or directory
 * CONFIG\_LOADFONT, CONFIG\_SETFONT  --  console-tools/loadfont.c:33:20: error: sys/kd.h: No such file or directory

* others
 * CONFIG\_EJECT  --  miscutils/eject.c:30:21: error: scsi/sg.h: No such file or directory
 * CONFIG\_FEATURE\_HAVE\_RPC, CONFIG\_FEATURE\_INETD\_RPC  --  networking/inetd.c:176:22: error: rpc/rpc.h: No such file or directory
 * CONFIG\_FEATURE\_IFCONFIG\_SLIP  --  networking/ifconfig.c:59:26: error: net/if\_slip.h: No such file or directory
 * CONFIG\_FEATURE\_SHADOWPASSWDS, CONFIG\_USE\_BB\_SHADOW  --  include/libbb.h:61:22: error: shadow.h: No such file or directory
 * CONFIG\_HUSH  --  **has patch**  --  shell/hush.c:89:18: error: glob.h: No such file or directory
 * CONFIG\_IFENSLAVE  --  networking/ifenslave.c:132:30: error: linux/if\_bonding.h: No such file or directory
 * CONFIG\_IFPLUGD  --  networking/ifplugd.c:38:23: error: linux/mii.h: No such file or directory
 * CONFIG\_IPCRM  --  **has patch**  --  util-linux/ipcrm.c:25:21: error: sys/shm.h: No such file or directory
 * CONFIG\_MT  --  miscutils/mt.c:19:22: error: sys/mtio.h: No such file or directory
 * CONFIG\_NTPD  --  networking/ntpd.c:49:23: error: sys/timex.h: No such file or directory
 * CONFIG\_SETARCH  --  util-linux/setarch.c:23:29: error: sys/personality.h: No such file or directory
 * CONFIG\_WATCHDOG  --  **has patch**  --  miscutils/watchdog.c:24:28: error: linux/watchdog.h: No such file or directory
 * CONFIG\_UBI*  --  **has patch**  --  miscutils/ubi\_tools.c:67:26: error: mtd/ubi-user.h: No such file or directory
  * disables CONFIG\_UBIATTACH, CONFIG\_UBIDETACH, CONFIG\_UBIMKVOL, CONFIG\_UBIRMVOL, CONFIG\_UBIRSVOL, CONFIG\_UBIUPDATEVOL

Config options that give a linking error
----------------------------------------
Androids libc implementation claims to implement the methods in the error, but surprisingly does not.

* mntent -- **has patch**
 * CONFIG\_DF  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_FSCK  --  undefined reference to 'setmntent', 'getmntent\_r', 'endmntent'
 * CONFIG\_MKFS\_EXT2  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_MOUNTPOINT  --  undefined reference to 'setmntent', 'endmntent'
 * CONFIG\_MOUNT  --  undefined reference to 'setmntent', 'getmntent\_r'
 * CONFIG\_UMOUNT  --  undefined reference to 'setmntent', 'getmntent\_r', 'endmntent'

* getsid -- **has patch**
 * CONFIG\_KILL  --  undefined reference to 'getsid'
 * CONFIG\_KILLALL  --  undefined reference to 'getsid'
 * CONFIG\_KILLALL5  --  undefined reference to 'getsid'
 * CONFIG\_PGREP  --  undefined reference to 'getsid'
 * CONFIG\_PKILL  --  undefined reference to 'getsid'

* stime -- **has patch**
 * CONFIG\_DATE  --  undefined reference to 'stime'
 * CONFIG\_RDATE  --  undefined reference to 'stime'

* others
 * CONFIG\_ADJTIMEX  --  **has patch**  --  undefined reference to 'adjtimex'
 * CONFIG\_FEATURE\_HTTPD\_AUTH\_MD5  --  undefined reference to 'crypt'
 * CONFIG\_HOSTID  --  undefined reference to 'gethostid'
 * CONFIG\_HOSTNAME  --  **has patch**  --  undefined reference to 'sethostname'
 * CONFIG\_LOGNAME  --  undefined reference to 'getlogin\_r'
 * CONFIG\_MICROCOM  --  **has patch**  --  undefined reference to 'cfsetspeed'
 * CONFIG\_NAMEIF  --  **has patch**  --  undefined reference to 'ether\_aton\_r'
 * CONFIG\_PIVOT\_ROOT  --  **has patch**  --  undefined reference to 'pivot\_root'
 * CONFIG\_STAT  --  **has patch** -- undefined reference to 'S\_TYPEISMQ', 'S\_TYPEISSEM', 'S\_TYPEISSHM'
 * CONFIG\_UDHCPD  --  **has patch**  --  undefined reference to 'ether\_aton\_r'
