windres cube-server.rc res.o
valac --disable-assert -g -d output -X "res.o" --cc=gcc --thread --target-glib=2.32 --pkg gio-2.0 --pkg gee-0.8 --pkg posix --pkg soup-2.4 -o cube-server.exe *.vala