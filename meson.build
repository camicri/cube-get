project('cube_get', 'vala', 'c',
    version : '4.4.0',
)

subdir('src')

run_target('release', command: ['./scripts/release.sh', meson.project_version()])
run_target('release-windows', command: ['bash', './scripts/release-windows.sh', meson.project_version()])