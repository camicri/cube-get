<p align="center">
<img src="https://camicri.github.io/camicri-cube/_media/cubelogo.png">
</p>

# Camicri Cube Server (cube-get)
Portable and offline package manager for Linux
[![Build Status](https://travis-ci.com/camicri/cube-get.svg?branch=master)](https://travis-ci.com/camicri/cube-get)

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
Be sure to perform build and release first as this will prepare necessary files (including `cube-vue`) and project directories on `builddir`.
Main directory will be generated at `builddir/cube-get`. Full path is required on `--parent-directory`.
```
./builddir/src/cube-get --parent-directory=/home/cami/repos/cube-get/builddir/cube-get
```

### Development
Use VSCode as IDE with [Vala language server](https://marketplace.visualstudio.com/items?itemName=philippejer.vala-language-client&ssr=false#overview) installed.
