# Copyright © 2004 Scott James Remnant <scott@netsplit.com>
# Copyright © 2007 Nicolas François <nicolas.francois@centraliens.net>
# Copyright © 2006, 2009-2012, 2014-2015 Guillem Jover <guillem@debian.org>

# DPKG_LIB_MD
# -----------
# Check for the message digest library.
AC_DEFUN([DPKG_LIB_MD], [
  AC_ARG_VAR([MD_LIBS], [linker flags for md library])
  AC_ARG_WITH([libmd],
    [AS_HELP_STRING([--with-libmd],
      [use libmd library for message digest functions])])
  AS_IF([test "x$with_libmd" != "xno"], [
    AC_CHECK_HEADERS([md5.h], [
      AC_CHECK_LIB([md], [MD5Init], [
        with_libmd="yes"
      ], [
        AC_MSG_FAILURE([md5 digest not found in libmd])
      ])
    ])
  ])
  AS_IF([test "x$with_libmd" = "xyes"], [MD_LIBS="-lmd"])
  AM_CONDITIONAL([HAVE_LIBMD_MD5], [test "x$ac_cv_lib_md_MD5Init" = "xyes"])
])# DPKG_LIB_MD

# DPKG_WITH_COMPRESS_LIB(NAME, HEADER, FUNC)
# -------------------------------------------------
# Check for availability of a compression library.
AC_DEFUN([DPKG_WITH_COMPRESS_LIB], [
  AC_ARG_VAR(AS_TR_CPP($1)[_LIBS], [linker flags for $1 library])
  AC_ARG_WITH([lib$1],
    [AS_HELP_STRING([--with-lib$1],
      [use $1 library for compression and decompression])])
  AS_IF([test "x$with_lib$1" != "xno"], [
    AC_CHECK_LIB([$1], [$3], [
      AC_DEFINE([WITH_LIB]AS_TR_CPP($1), 1,
        [Define to 1 to use $1 library rather than console tool])
      AS_IF([test "x$with_lib$1" = "xstatic"], [
        dpkg_$1_libs="-Wl,-Bstatic -l$1 -Wl,-Bdynamic"
      ], [
        dpkg_$1_libs="-l$1"
      ])
      AS_TR_CPP($1)_LIBS="${AS_TR_CPP($1)_LIBS:+$AS_TR_CPP($1)_LIBS }$dpkg_$1_libs"
      with_lib$1="yes"
    ], [
      AS_IF([test -n "$with_lib$1"], [
        AC_MSG_FAILURE([$1 library not found])
      ])
    ])

    AC_CHECK_HEADER([$2], [], [
      AS_IF([test -n "$with_lib$1"], [
        AC_MSG_FAILURE([lib$1 header not found])
      ])
    ])
  ])
])# DPKG_WITH_COMPRESS_LIB

# DPKG_LIB_Z
# -------------
# Check for z library.
AC_DEFUN([DPKG_LIB_Z], [
  DPKG_WITH_COMPRESS_LIB([z], [zlib.h], [gzdopen])
])# DPKG_LIB_Z

# DPKG_LIB_LZMA
# -------------
# Check for lzma library.
AC_DEFUN([DPKG_LIB_LZMA], [
  DPKG_WITH_COMPRESS_LIB([lzma], [lzma.h], [lzma_alone_decoder])
  AC_CHECK_LIB([lzma], [lzma_stream_encoder_mt], [
    AC_DEFINE([HAVE_LZMA_MT], [1], [xz multithreaded compression support])
  ])
])# DPKG_LIB_LZMA

# DPKG_LIB_BZ2
# ------------
# Check for bz2 library.
AC_DEFUN([DPKG_LIB_BZ2], [
  DPKG_WITH_COMPRESS_LIB([bz2], [bzlib.h], [BZ2_bzdopen])
])# DPKG_LIB_BZ2

# DPKG_LIB_SELINUX
# ----------------
# Check for selinux library.
AC_DEFUN([DPKG_LIB_SELINUX], [
  AC_REQUIRE([PKG_PROG_PKG_CONFIG])
  m4_ifndef([PKG_PROG_PKG_CONFIG], [m4_fatal([missing pkg-config macros])])
  AC_ARG_VAR([SELINUX_LIBS], [linker flags for selinux library])dnl
  AC_ARG_WITH([libselinux],
    [AS_HELP_STRING([--with-libselinux],
      [use selinux library to set security contexts])])
  AS_IF([test "x$with_libselinux" != "xno"], [
    AC_CHECK_LIB([selinux], [is_selinux_enabled], [
      AC_DEFINE([WITH_LIBSELINUX], [1],
        [Define to 1 to compile in SELinux support])
      PKG_CHECK_EXISTS([libselinux], [
        AS_IF([test "x$with_selinux" = "xstatic"], [
          dpkg_selinux_libs="-Wl,-Bstatic "$($PKG_CONFIG --static --libs libselinux)" -Wl,-Bdynamic"
        ], [
          dpkg_selinux_libs=$($PKG_CONFIG --libs libselinux)
        ])
      ], [
        AS_IF([test "x$with_libselinux" = "xstatic"], [
          dpkg_selinux_libs="-Wl,-Bstatic -lselinux -lsepol -Wl,-Bdynamic"
        ], [
          dpkg_selinux_libs="-lselinux"
        ])
      ])
      SELINUX_LIBS="${SELINUX_LIBS:+$SELINUX_LIBS }$dpkg_selinux_libs"
      with_libselinux="yes"
    ], [
      AS_IF([test -n "$with_libselinux"], [
        AC_MSG_FAILURE([selinux library not found])
      ])
    ])
    AC_CHECK_LIB([selinux], [setexecfilecon], [
      AC_DEFINE([HAVE_SETEXECFILECON], [1],
                [Define to 1 if SELinux setexecfilecon is present])
    ])

    AC_CHECK_HEADER([selinux/selinux.h], [], [
      AS_IF([test -n "$with_libselinux"], [
        AC_MSG_FAILURE([selinux header not found])
      ])
    ])
  ])
  AM_CONDITIONAL([WITH_LIBSELINUX], [test "x$with_libselinux" = "xyes"])
  AM_CONDITIONAL([HAVE_SETEXECFILECON],
    [test "x$ac_cv_lib_selinux_setexecfilecon" = "xyes"])
])# DPKG_LIB_SELINUX

# _DPKG_CHECK_LIB_CURSES_NARROW
# -----------------------------
# Check for narrow curses library.
AC_DEFUN([_DPKG_CHECK_LIB_CURSES_NARROW], [
  AC_CHECK_LIB([ncurses], [initscr], [
    CURSES_LIBS="${CURSES_LIBS:+$CURSES_LIBS }-lncurses"
  ], [
    AC_CHECK_LIB([curses], [initscr], [
      CURSES_LIBS="${CURSES_LIBS:+$CURSES_LIBS }-lcurses"
    ], [
      AC_MSG_ERROR([no curses library found])
    ])
  ])
])# DPKG_CHECK_LIB_CURSES_NARROW

# DPKG_LIB_CURSES
# ---------------
# Check for curses library.
AC_DEFUN([DPKG_LIB_CURSES], [
  AC_REQUIRE([DPKG_UNICODE])
  AC_ARG_VAR([CURSES_LIBS], [linker flags for curses library])dnl
  AC_CHECK_HEADERS([ncurses/ncurses.h ncurses.h curses.h ncurses/term.h term.h],
                   [have_curses_header=yes])
  AS_IF([test "x$USE_UNICODE" = "xyes"], [
    AC_CHECK_HEADERS([ncursesw/ncurses.h ncursesw/term.h],
                     [have_curses_header=yes])
    AC_CHECK_LIB([ncursesw], [initscr], [
      CURSES_LIBS="${CURSES_LIBS:+$CURSES_LIBS }-lncursesw"
    ], [
      _DPKG_CHECK_LIB_CURSES_NARROW()
    ])
  ], [
    _DPKG_CHECK_LIB_CURSES_NARROW()
  ])
  AS_IF([test "x$have_curses_header" != "xyes"], [
    AC_MSG_FAILURE([curses header not found])
  ])
  have_libcurses=yes
])# DPKG_LIB_CURSES

# DPKG_LIB_PS
# -----------
# Check for GNU/Hurd ps library
AC_DEFUN([DPKG_LIB_PS], [
  AC_ARG_VAR([PS_LIBS], [linker flags for ps library])dnl
  AC_CHECK_LIB([ps], [proc_stat_list_create], [
    PS_LIBS="-lps"
    have_libps=yes
  ])
])# DPKG_LIB_PS

# DPKG_LIB_KVM
# ------------
# Check for BSD kvm library
AC_DEFUN([DPKG_LIB_KVM], [
  AC_ARG_VAR([KVM_LIBS], [linker flags for kvm library])dnl
  AC_CHECK_LIB([kvm], [kvm_openfiles], [
    KVM_LIBS="-lkvm"
    have_libkvm=yes
  ])
])# DPKG_LIB_KVM
