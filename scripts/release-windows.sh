version=$1
cd "${MESON_BUILD_ROOT}"

####################### INITIAL SETUP #########################################

mkdir -p cube-get
mkdir -p cube-get/cube-system/lib
mkdir -p cube-get/cube-system/data/bin
mkdir -p cube-get/cube-system/data/server
mkdir -p cube-get/cube-system/data/server/html
mkdir -p cube-get/projects

#  CI will automatically upload cube-vue release to build directory
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

####################### LIBRARY DEPENDENCY RELEASE ############################

# Copy library dependencies
cp /mingw64/bin/gspawn-win64-helper-console.exe cube-get/
cp /mingw64/bin/libbrotlicommon.dll cube-get/
cp /mingw64/bin/libbrotlidec.dll cube-get/
cp /mingw64/bin/libffi-8.dll cube-get/
cp /mingw64/bin/libgcc_s_seh-1.dll cube-get/
cp /mingw64/bin/libgee-0.8-2.dll cube-get/
cp /mingw64/bin/libgio-2.0-0.dll cube-get/
cp /mingw64/bin/libglib-2.0-0.dll cube-get/
cp /mingw64/bin/libgmodule-2.0-0.dll cube-get/
cp /mingw64/bin/libgobject-2.0-0.dll cube-get/
cp /mingw64/bin/libiconv-2.dll cube-get/
cp /mingw64/bin/libidn2-0.dll cube-get/
cp /mingw64/bin/libintl-8.dll cube-get/
cp /mingw64/bin/liblzma-5.dll cube-get/
cp /mingw64/bin/libpcre2-32-0.dll cube-get/
cp /mingw64/bin/libpsl-5.dll cube-get/
cp /mingw64/bin/libsoup-2.4-1.dll cube-get/
cp /mingw64/bin/libsqlite3-0.dll cube-get/
cp /mingw64/bin/libunistring-2.dll cube-get/
cp /mingw64/bin/libwinpthread-1.dll cube-get/
cp /mingw64/bin/libxml2-2.dll cube-get/
cp /mingw64/bin/zlib1.dll cube-get/
cp /bin/msys-2.0.dll cube-get/

# Copy binary dependencies
cp /usr/bin/axel cube-get/cube-system/data/bin/
cp /mingw64/bin/aria2c cube-get/cube-system/data/bin/

####################### DOCUMENTATION RELEASE #################################

# Copy documents
cp ../LICENSE cube-get/LICENSE

####################### PACKAGING AND RELEASE #################################

cp src/cube-get.exe cube-get/

zip -r cube-get_$version"_windows.zip" cube-get/*
echo "Release files: "
ls -l *.zip