<p align="center">
<img src="https://cube.camicri.com/_media/cubelogo.png">
</p>

# CubeGet
Portable and offline package manager for Linux
![Build Status](https://github.com/camicri/cube-get/actions/workflows/build.yml/badge.svg)

### Build setup
```
pip3 install meson ninja
sudo apt-add-repository --yes ppa:vala-team
sudo apt-get update
sudo apt-get -y install valac libglib2.0-dev libsoup2.4-dev libgee-0.8-dev axel aria2
meson builddir
ninja -C builddir
```
### Release
```
ninja -C builddir release
```

This will generate `cube-get_version_linux.zip` on builddir directory.

### Run locally
Make sure to perform build and release first as this will prepare necessary files (including `cube-vue`) and project directories on `builddir`.
Main directory will be generated at `builddir/cube-get`. Full path is required on `--parent-directory`.
```
ninja -C builddir && ./builddir/src/cube-get --parent-directory=/home/cami/repos/cube-get/builddir/cube-get
```

### Development
Preferably Visual Studio Code as IDE with Vala plugins and [Vala language server](https://github.com/benwaffle/vala-language-server) installed.
