AC_INIT([dnfstrap], [0.3])

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIRS([m4])

AM_INIT_AUTOMAKE([foreign subdir-objects])
AM_SILENT_RULES([yes])

AM_PROG_VALAC([0.28])
AM_PROG_CC_C_O

CFLAGS="$CFLAGS -w"

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

GLIB_REQUIRED=2.40.0
AC_SUBST([GLIB_REQUIRED])

PKG_CHECK_MODULES(dnfstrap_U, [
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  libdnf
])

AC_SUBST([dnfstrap_U_VALAFLAGS], ["--pkg gio-2.0 \
          --target-glib=$GLIB_REQUIRED \
          --enable-experimental \
          --enable-experimental-non-null \
          --fatal-warnings"])

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_CONFIG_FILES([
  Makefile
  src/Makefile
])
AC_OUTPUT
