#!/bin/bash

version=$1
cd "${MESON_BUILD_ROOT}"

####################### INITIAL SETUP #########################################

mkdir -p cube-get
mkdir -p cube-get/cube-system/lib
mkdir -p cube-get/cube-system/data/bin
mkdir -p cube-get/cube-system/data/server
mkdir -p cube-get/cube-system/data/server/html
mkdir -p cube-get/projects

####################### CUBE VUE RELEASE ######################################

# CI will automatically upload cube-vue release to build directory
if [ -f "cube-vue-dist.zip" ]; then
    mkdir cube-vue
    unzip cube-vue-dist.zip -d cube-vue/
    rm cube-vue-dist.zip
else
    # Build cube-vue
    git clone https://github.com/camicri/cube-vue.git
    cd cube-vue
    npm install
    npm run build
    cd ..
fi

cp -r cube-vue/dist/static/* cube-get/cube-system/data/server/
cp cube-vue/dist/index.html cube-get/cube-system/data/server/html/

####################### BINARY APP DIR RELEASE ################################

ninja
cp -R ../template/cube-get.AppDir .
cp src/cube-get cube-get.AppDir/

if [ ! -f "./appimagetool-x86_64.AppImage" ]; then
    wget "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod a+x appimagetool-x86_64.AppImage
fi

./appimagetool-x86_64.AppImage cube-get.AppDir

####################### LIBRARY DEPENDENCY RELEASE ############################

# Copy library dependencies
cp /usr/lib/x86_64-linux-gnu/libgee-0.8.so.2 cube-get/cube-system/lib/
cp /usr/lib/x86_64-linux-gnu/libsoup-2.4.so.1 cube-get/cube-system/lib/

# Copy binary dependencies
cp /usr/bin/axel cube-get/cube-system/data/bin/
cp /usr/bin/aria2c cube-get/cube-system/data/bin/

####################### DOCUMENTATION RELEASE #################################

# Copy documents
cp ../LICENSE cube-get/LICENSE

####################### PACKAGING AND RELEASE #################################

mv CubeGet-x86_64.AppImage cube-get/cube-get

zip -r cube-get_$version"_linux.zip" cube-get/*
echo "Release files: "
ls -l *.zip