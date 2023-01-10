{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, libtool
, pkg-config
, gnutls
, libgcrypt
, libtasn1
, glib
, libplist
, libusbmuxd
, callPackage
, openssl
, libusb
, git
, autoconf
, avahi
, libimobiledevice
, enableDebugging
}:

stdenv.mkDerivation rec {
  pname = "usbmuxd2";
  version = "753b79eaf317c56df6c8b1fb6da5847cc54a0bb0";

  src = fetchFromGitHub {
    owner = "tihmstar";
    repo = pname;
    rev = "753b79eaf317c56df6c8b1fb6da5847cc54a0bb0";
    sha256 = "0n3xgqj03vwf1wvp9iz2vil4s5lhc7q5svp17mfmmh49lgffvmjg";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    libtool
    pkg-config
    git
    autoconf
    (callPackage ./libgeneral.nix {})
  ];

  propagatedBuildInputs = [
    glib
    libusb

    #(callPackage ./libimobiledevice.nix {})
    #(enableDebugging (callPackage ./libimobiledevice_unstable-2021-11-24.nix {}))
    (callPackage ./libimobiledevice_unstable-2021-11-24.nix {})
    #libimobiledevice
    
    libplist
    #libusbmuxd
    #(enableDebugging (callPackage ./libusbmuxd.nix {}))
    (callPackage ./libusbmuxd.nix {})
    # (libusbmuxd.overrideAttrs (oldAttrs: rec {
    #   patchPhase = (oldAttrs.patchPhase or "") + ''
    #     #substituteInPlace src/idevice.c --replace 'if (res > 0) {' 'printf("usbmuxd_get_device returned: %d\n", res); if (res > 0) {'
    #   '';
    # }))
    (callPackage ./libimobiledevice-glue.nix {})
    avahi
  ];

  patchPhase = ''
    #git clone --bare https://github.com/tihmstar/libgeneral.git .git

    substituteInPlace configure.ac \
      --replace "m4_esyscmd([git rev-list --count HEAD | tr -d '\n'])" 46 \
      --replace "m4_esyscmd([git rev-parse HEAD | tr -d '\n'])" 753b79eaf317c56df6c8b1fb6da5847cc54a0bb0 \
      --replace "PKG_CHECK_MODULES(libimobiledevice, libimobiledevice-1.0 >= 1.2.1, have_limd=yes, have_limd=no)" "have_limd=yes" \
      --replace "CXXFLAGS+=\" -std=c++17\"" "
        CXXFLAGS+=\" -std=c++17\"
        LDFLAGS+=\" $($PKG_CONFIG --libs libimobiledevice-1.0) -limobiledevice-1.0\"
        AC_DEFINE([SOCKET_PATH], \"/var/run/usbmuxd.d/usbmuxd\", [Desc]) # Optional, only for more flexible perms on the /var/run pid lock and this socket created by ClientManager.cpp
      "
      # Note for the above: AC_MSG_ERROR([$($PKG_CONFIG --list-all 2>&1)]) #<--doesn't work for testing purposes

      #--replace "udev/Makefile" "" \
      #--replace "systemd/Makefile" ""

    substituteInPlace usbmuxd2/Muxer.cpp \
      --replace "#include \"Muxer.hpp\"" "
        #include \"Muxer.hpp\"
        #include \"Manager/WIFIDeviceManager-avahi.hpp\"
      " \
      --replace "_finalUnrefEvent.wait();" "fprintf(stderr, \"_finalUnrefEvent.members(): %ju\n\", _finalUnrefEvent.members()); if (_finalUnrefEvent.members() > 0) _finalUnrefEvent.wait();" # <--Optional stuff
    
    substituteInPlace usbmuxd2/Manager/WIFIDeviceManager.cpp \
      --replace "#include \"WIFIDeviceManager.hpp\"" "
        #include \"WIFIDeviceManager.hpp\"
        #include \"Manager/WIFIDeviceManager-avahi.hpp\"
      "

    # Optional, only for more flexible perms on the /var/run pid lock
    substituteInPlace usbmuxd2/main.cpp \
      --replace "unlink(lockfile);" "if (unlink(lockfile) == -1) { perror(\"unlink failed\"); }" \
      --replace "int main(int argc, const char * argv[]) {" "
        int main(int argc, const char * argv[]) {
          struct group* gr;
      " \
      --replace "static const char *lockfile = \"/var/run/usbmuxd.pid\";" \
        "#include <grp.h>
static const char *lockfile = \"/var/run/usbmuxd.d/usbmuxd.pid\";" \
      --replace "cretassure((lfd = open(lockfile, O_RDONLY|O_CREAT, 0644)) != -1, \"Could not open lockfile\");" "
        mkdir(\"/var/run/usbmuxd.d\", 0775);
        if (chmod(\"/var/run/usbmuxd.d\", 0775) == -1) { // We need to do this again due to umask removing from the perms in any open or mkdir system calls. umask is like a subtraction from those perms to provide sensible defaults for 0777 basically.
            perror(\"Error in chmod for usbmuxd.d\");
        }
        gr = getgrnam(\"iosbackup\");
        if (gr != nullptr) {
          if (chown(\"/var/run/usbmuxd.d\", 0 /*root*/, gr->gr_gid) == -1)
            perror(\"Error in chown for usbmuxd.d\");
        }
        else {
          fputs(\"getgrnam failed, continuing anyway\", stderr);
        }
        if ((lfd = open(lockfile, O_RDONLY|O_CREAT, 0664)) == -1) {
          perror(\"Could not open lockfile in 1st open call\");
          goto error;
        }
        if (gr != nullptr) {
          fprintf(stderr, \"chown for lockfile: %ju %ju\n\", getuid(), gr->gr_gid);
          if (chown(lockfile, getuid(), gr->gr_gid) == -1)
            perror(\"Error in chown for lockfile\");
          if (chmod(lockfile, 0664) == -1) // We need to do this again due to umask removing from the perms in any open or mkdir system calls. umask is like a subtraction from those perms to provide sensible defaults for 0777 basically.
            perror(\"Error in chmod for lockfile\");
        }
      " \
      --replace "cretassure((lfd = open(lockfile, O_WRONLY|O_CREAT|O_TRUNC|O_EXCL, 0644)) != -1, \"Could not open lockfile\");" "
      if ((lfd = open(lockfile, O_WRONLY|O_CREAT|O_TRUNC|O_EXCL, 0664)) == -1) {
        perror(\"Could not open lockfile in 2nd open call\");
        goto error;
      }" \
      --replace "static pthread_mutex_t mlck = {};" "static int result; static int sig; static sigset_t sigset_; static bool exitMain = false;" \
      --replace "cassure(!pthread_mutex_init(&mlck, NULL));" "" \
      --replace "cassure(!pthread_mutex_lock(&mlck));" "" \
      --replace "cassure(!pthread_mutex_unlock(&mlck));" "exitMain = true; return;" \
      --replace "pthread_mutex_lock(&mlck);" "
  sigemptyset(&sigset_);
  //sigaddset(&sigset_, SIGUSR1);
  sigfillset(&sigset_); // Block all signals (the signal handlers won't run, only sigwait dequeues them basically) ( https://stackoverflow.com/questions/8093755/how-to-block-all-signals-in-thread-without-using-sigwait , https://stackoverflow.com/questions/6326290/about-the-ambiguous-description-of-sigwait )
  sigprocmask(SIG_BLOCK, &sigset_, NULL);

  do {
    result = sigwait(&sigset_, &sig);
    if(result == 0) {
      printf(\"sigwait got signal: %d\n\", sig);
      handle_signal(sig); // Manually invoke the signal handler
    }
    else {
      fputs(\"sigwait returned error\", stderr);
      break;
    }
  } while (!exitMain);
      " \
    --replace "close(lfd);" "close(lfd); if (chown(lockfile, getuid(), gr->gr_gid) == -1) {
            perror(\"Error in chown for lockfile\"); }
          if (chmod(lockfile, 0664) == -1) { // We need to do this again due to umask removing from the perms in any open or mkdir system calls. umask is like a subtraction from those perms to provide sensible defaults for 0777 basically.
            perror(\"Error in chmod for lockfile\"); }"
    #--replace "int main(int argc, const char * argv[]) {" "int main(int argc, const char * argv[]) { libusbmuxd_set_debug_level(99); // (arbitrary number used here to get it relatively high)"
    # (^last `--replace` is optional)

    # Optional, only for more flexible perms on the /var/run pid lock, *except* there is a typo fix for the unlink() error handling in `retassure(unlink(socket_path) != 1 || errno == ENOENT, \"unlink(%s) failed: %s\", socket_path, strerror(errno));` which should be `retassure(unlink(socket_path) != -1 || errno == ENOENT, \"unlink(%s) failed: %s\", socket_path, strerror(errno));`
    substituteInPlace usbmuxd2/Manager/ClientManager.cpp \
      --replace "ClientManager::ClientManager(std::shared_ptr<gref_Muxer> mux)" "#include <sys/types.h>
#include <grp.h>
ClientManager::ClientManager(std::shared_ptr<gref_Muxer> mux)" \
      --replace "struct sockaddr_un bind_addr = {};" "struct sockaddr_un bind_addr = {}; struct group* gr;" \
      --replace "retassure(unlink(socket_path) != 1 || errno == ENOENT, \"unlink(%s) failed: %s\", socket_path, strerror(errno));" "retassure(unlink(socket_path) != -1 || errno == ENOENT, \"unlink(%s) failed: %s\", socket_path, strerror(errno));" \
      --replace "assure(!chmod(socket_path, 0666));" "" \
      --replace "retassure((_listenfd = socket(AF_UNIX, SOCK_STREAM, 0))>=0, \"socket() failed: %s\", strerror(errno));" "retassure((_listenfd = socket(AF_UNIX, SOCK_STREAM, 0))>=0, \"socket() failed: %s\", strerror(errno)); if (fchmod(_listenfd, 0660) == -1){ perror(\"fchmod in ClientManager failed\"); } else {
        gr = getgrnam(\"iosbackup\");
        if (gr != nullptr) {
           if (chown(socket_path, getuid(), gr->gr_gid) == -1){ perror(\"chmod in ClientManager failed\"); }
        }
        else {
          fputs(\"getgrnam failed in ClientManager, continuing anyway\", stderr);
        }}"
    # ^^ https://stackoverflow.com/questions/35424970/unix-socket-permissions-linux , https://stackoverflow.com/questions/11781134/change-linux-socket-file-permissions/74329441#74329441 for the fchmod -- it should happen before the bind() call and after socket() for best security, since no other process can use it before bind() since it has no filepath yet, so we can set perms on the file referred to by the fd before the bind call.

    # Optional, for nicer info about errors
    substituteInPlace usbmuxd2/Devices/WIFIDevice.cpp \
      --replace "assure(!idevice_new_with_options(&_idev,_serial, IDEVICE_LOOKUP_NETWORK));" "idevice_error_t retval = idevice_new_with_options(&_idev,_serial, IDEVICE_LOOKUP_NETWORK);
    if (retval) {
	fprintf(stderr, \"idevice_new_with_options gave error: %d\n\", retval);
	// https://docs.libimobiledevice.org/libimobiledevice/latest/libimobiledevice_8h.html#af8700e72c67d927a6a9ec7688fe87c1f :
	// idevice_error_t {
	//   IDEVICE_E_SUCCESS = 0,
	//   IDEVICE_E_INVALID_ARG = -1,
	//   IDEVICE_E_UNKNOWN_ERROR = -2,
	//   IDEVICE_E_NO_DEVICE = -3,
	//   IDEVICE_E_NOT_ENOUGH_DATA = -4,
	//   IDEVICE_E_SSL_ERROR = -6,
	//   IDEVICE_E_TIMEOUT = -7
	// }
	//  	Error Codes.
    }
    assure(!retval);"
  '';

  #configureFlags = [ "--disable-openssl" "--without-cython" ];
  #configureFlags = [ "--with-udevrulesdir=${out}/lib/udev" ];

  preConfigure = ''
    echo "@@@@@@@@@@@@@@@@@@@@@@ preConfigure"
    configureFlags="$configureFlags --with-udevrulesdir=$out/lib/udev/rules.d"
    configureFlags="$configureFlags --with-systemdsystemunitdir=$out/lib/systemd/system"
    #configureFlags="$configureFlags --with-libimobiledevice"
  '';

  #autoreconfFlags = [ "--enable-debug" ];

  autoreconfPhase = ''
    runHook preAutoreconf
    NOCONFIGURE=1 ./autogen.sh ''${autoreconfFlags:---install --force --verbose} --enable-debug
    runHook postAutoreconf
  '';

  configureFlags = [ "--enable-debug" ];

  dontStrip = true;
  
  meta = with lib; {
    homepage = "https://github.com/tihmstar/usbmuxd2";
    platforms = platforms.linux ++ platforms.darwin;
  };
}

