## Process this file with automake to produce Makefile.in

## Created by Anjuta



AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(CUBE_SERVER_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

bin_PROGRAMS = cube_server

cube_server_SOURCES = \
	config.vapi system-information.vala sources.vala source-manager.vala repository-manager.vala project-manager.vala project.vala process-manager.vala package-version.vala package.vala loggy.vala linux-information.vala installation-manager.vala helpers.vala download-manager.vala dependency-manager.vala cube-system.vala configuration-manager.vala base-manager.vala axel-downloader.vala apt-information.vala apt-constraint.vala package-query.vala server-system.vala server-command-project.vala server-command-repository.vala server.vala server-router.vala server-command-download.vala server-command-install.vala server-command-update.vala server-command-system.vala server-command-source.vala server-command-configuration.vala cube_server.vala cube-information.vala aria2c-downloader.vala shellinabox.vala

cube_server_VALAFLAGS =  --thread --target-glib=2.32 --pkg gio-2.0 --pkg gee-0.8 --pkg libsoup-2.4 --pkg posix

cube_server_LDFLAGS = \
	-Wl,--export-dynamic

cube_server_LDADD = $(CUBE_SERVER_LIBS)


EXTRA_DIST = $(ui_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(pkgdatadir)

