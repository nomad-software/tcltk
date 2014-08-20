#tcltk
**Bindings to Tcl/Tk for the D programming language**

---

## Tcl/Tk versions

Tcl/Tk v8.6.1+ is tagged and supported in the master branch. Tcl/Tl v8.5.11 
support is available via a tag.

## Supported platforms
These bindings have been developed with the latest DMD compiler. Other 
compilers have not been tested but should build fine.

### Linux
Should build just fine.

### Mac OSX
Should build just fine.

### Windows
Should build just fine.

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

To avoid relying on a Tcl installation and to create fully independant
programs, copy the DLL's and the initialization script library directory into
the root of the finished application. These files can be conveniently found in
the `dist` folder within this repository. Your finished application's directory
would then look something like this:
```
project
├── app.exe
├── tcl86.dll
├── tk86.dll
└── library
    └── *.tcl files
```

#### Linux/Mac OSX

On Linux and Mac OSX things are a little easier as both operating systems have
Tcl/Tk installed by default. If however they do not have the latest version,
the libraries can be updated via their respective package managers. The linked
libraries are **libtcl** and **libtk**.
