#####################################################
#
# HOW TO BUILD
# ------------
#
# mkdir build
# cd build
# cmake -DCMAKE_INSTALL_PREFIX=/usr ../
# make
# sudo make install
#
#####################################################

#project name
project ( cube-server )

cmake_minimum_required (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${CMAKE_CURRENT_SOURCE_DIR}/data")
set (CUBESYSTEMDATADIR "${PKGDATADIR}/cube-system")

set (EXEC_NAME "cube-server")
set (RELEASE_NAME "Camicri Cube Server")
set (VERSION "0.1")
set (VERSION_INFO "Initial Release")

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED glib-2.0 gio-2.0 gee-0.8 libsoup-2.4)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)

# make sure we use vala
include(ValaVersion)

# make sure it's the desired version of vala
#ensure_vala_version("0.18")

# files we want to compile
include(ValaPrecompile)

vala_precompile(VALA_C ${EXEC_NAME}
    #Vala Sources Here
    src/apt-constraint.vala
    src/apt-information.vala
    src/aria2c-downloader.vala
    src/axel-downloader.vala
    src/base-manager.vala
    src/configuration-manager.vala
    src/cube-information.vala
    src/cube_server.vala
    src/cube-system.vala
    src/dependency-manager.vala
    src/download-manager.vala
    src/helpers.vala
    src/installation-manager.vala
    src/linux-information.vala
    src/loggy.vala
    src/package-query.vala
    src/package.vala
    src/package-version.vala
    src/process-manager.vala
    src/project-manager.vala
    src/project.vala
    src/repository-manager.vala
    src/server-command-configuration.vala
    src/server-command-download.vala
    src/server-command-install.vala
    src/server-command-project.vala
    src/server-command-repository.vala
    src/server-command-source.vala
    src/server-command-system.vala
    src/server-command-update.vala
    src/server-router.vala
    src/server-system.vala
    src/server.vala
    src/shellinabox.vala
    src/source-manager.vala
    src/sources.vala
    src/system-information.vala
PACKAGES
    #Valac Packages HERE
    gio-2.0
    gee-0.8
	libsoup-2.4
OPTIONS
    #Valac Options
    --thread --target-glib=2.32
GENERATE_VAPI
    #VALA Generated API Name
    cube-server
GENERATE_HEADER
    #VALA Generated Header Here
    cube-server
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/${EXEC_NAME}.desktop
    DESTINATION ${DATADIR}/applications/
)

# install cube-server icon
install (
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/${EXEC_NAME}.png
    DESTINATION ${DATADIR}/icons/hicolor/48x48/apps
)

# install the cube system
install (
    DIRECTORY ${CUBESYSTEMDATADIR}
    DESTINATION ${DATADIR}
)

# make cube-system bin directory executable
# install(CODE "execute_process ( COMMAND \"chmod -R +x ${CUBESYSTEMDATADIR}/data/bin\" )" )
