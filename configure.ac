dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(cube_server, 0.1)

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.11])

AM_SILENT_RULES([yes])

AC_PROG_CC


LT_INIT


dnl Check for vala
AM_PROG_VALAC([0.10.0])


PKG_CHECK_MODULES(CUBE_SERVER, [gio-2.0 gee-0.8, libsoup-2.4])


AC_OUTPUT([
Makefile
src/Makefile

])
