# Camicri Cube
Portable and offline package manager for Linux

Camicri Cube is a portable package manager aiming to help Linux users without internet access to download applications on another internet connected computer, and install them back to their original computer, offline.

Camicri Cube is a server application built in combination of Vala and Vue.

For the downloadable binary files for Linux and Windows, see our [Releases](https://github.com/camicri/camicri-cube/releases) page.

## Why Vala?

This program is currently written in Vala, a programming language created by GNOME community. I picked this language since it has a great integration with Linux distributions, all thanks to GNOME's GLib library. It also have less dependency to libraries (It can work as long as there is glib in the system), achieving high portability and compatibility to other Linux distributions. The program produced also consumes small amount of memory, which is really needed since the application itself manipulates atleast 40k Linux packages.

## Why Cube "Server"?

Cube is originally written in C#, and using WinForms (yuck) and eventually in GTK+ (nah). And after several releases using these libraries, I received many reports on the compatibility of Cube in different Linux distributions (Also in Windows). The binary also became big, with a lot of shared libraries, making it 'less portable', and it is hard on my side to change the GUI since it is limited to what is given by the designer.

With that, I decided to rewrite Cube, remove all WinForms/GTK code and created a 'server like' design.

The current Cube is now using Vala's GIO HTTP server, exposing the Cube's functionalities as REST API calls, with the elegance and simplicity of VueJS to provide the user interface. And it looks better than the previous Cube!
