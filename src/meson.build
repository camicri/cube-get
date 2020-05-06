dependencies = [
    dependency('glib-2.0'),
    dependency('gee-0.8'),
    dependency('gio-2.0'),
    dependency('libsoup-2.4'),
    meson.get_compiler('vala').find_library('posix')
]

sources = [
    'core/apt-constraint.vala',
    'core/apt-information.vala',
    'core/aria2c-downloader.vala',
    'core/axel-downloader.vala',
    'core/base-manager.vala',
    'core/configuration-manager.vala',
    'core/cube-information.vala',
    'core/cube-system.vala',
    'core/dependency-manager.vala',
    'core/download-manager.vala',
    'core/helpers.vala',
    'core/installation-manager.vala',
    'core/linux-information.vala',
    'core/loggy.vala',
    'core/package-query.vala',
    'core/package.vala',
    'core/package-version.vala',
    'core/process-manager.vala',
    'core/project-manager.vala',
    'core/project.vala',
    'core/repository-manager.vala',
    'core/shellinabox.vala',
    'core/source-manager.vala',
    'core/sources.vala',
    'core/system-information.vala',
    'server/server-command-configuration.vala',
    'server/server-command-download.vala',
    'server/server-command-install.vala',
    'server/server-command-project.vala',
    'server/server-command-repository.vala',
    'server/server-command-source.vala',
    'server/server-command-system.vala',
    'server/server-command-update.vala',
    'server/server-router.vala',
    'server/server-system.vala',
    'server/server.vala',
    'cube-get.vala',
]

if build_machine.system() == 'windows'
    r = run_command('windres', '../template/windres/cube-server.rc', '../builddir/src/cube-server-res.o')
    if r.returncode() == 0
        # FIXME: vala argument -X is being ignored when -C (enabled by default) is present
        executable('cube-get', sources, dependencies: dependencies , vala_args: ['-X','../builddir/src/cube-server-res.o'])
    endif
else
    executable('cube-get', sources, dependencies: dependencies)
endif