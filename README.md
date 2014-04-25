#tcltk
**Bindings to Tcl/Tk for the D programming language**

---

## Tcl/Tk versions

Tcl/Tk v8.6.1 is tagged supported in the master branch. Tcl/Tl v8.5.11 support
is available via a tag.

## Dependencies

### Source code

Tcltk requires other D source libraries to correctly use and link against
pre-existing C libraries. The source dependencies are as follows:

 * https://github.com/nomad-software/x11 (Linux only)

Dub handles these automatically and during a build acquires them. While
building, the tcltk repository is configured to link against the required
Tcl/Tk libraries, hence they need to be installed for the application to
function.

### Libraries

Version **8.6.1** of the Tcl/Tk libraries or greater is required to be
installed.

#### Windows

On Windows you can download and install
[ActiveTcl](http://www.activestate.com/activetcl/downloads) from ActiveState
which is a fully supported professional library. This will install all needed
Tcl/Tk DLL's and initialization scripts. Once this is installed, building and
linking with dub will give immediate results. ActiveTcl also comes with a
[silent
install](http://community.activestate.com/faq/unattended-installation-a) option
if you want to include it as part of an installation.

If however you don't want to install Tcl/Tk and want the application to be
self-contained, you can copy the DLL's and the initialization script library
directory into the root of the finished application. These files can be
conveniently found in the `dist` folder within the
[tcktk](https://github.com/nomad-software/tcltk) repository. Your finished
application's directory would then look something like this:
```
project
├── app.exe
├── tcl86.dll
├── tk86.dll
├── zlib1.dll
└── library
    └── *.tcl files
```
I'm hoping once [this](https://github.com/rejectedsoftware/dub/issues/299) dub
issue is resolved this will become the default option on Windows and dub will
copy all required DLL's and files to the application's directory on every dub
build.

#### Linux/Mac OSX

On Linux and Mac OSX things are a little easier as both operating systems have
Tcl/Tk installed by default. If however they do not have the latest version,
the libraries can be updated via their respective package managers or install
ActiveTcl. The linked libraries are **libtcl** and **libtk**.
