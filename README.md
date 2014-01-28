#tcltk
**Bindings to Tcl/Tk for the D programming language**

---

## Tcl/Tk versions
Tcl/Tk v8.6.1 is supported in the master branch. Tcl/Tl v8.5.11 support is available via a tag. To be honest though you may as well just use master.

## Supported platforms
These bindings have been developed with DMD v2.064.2. Other compilers have not been tested but should build fine.

### Linux
Should build just fine.

### Mac OSX
Should build just fine.

### Windows
[ActiveState ActiveTcl](http://www.activestate.com/activetcl) must be installed.

#### 32bit DMD compiler on 64bit Windows
If compiling using the 32bit DMD compiler on Windows 64bit dub should recognise the 32bit build platform and use the 32bit DLLs. If not use the following option in the build command:

    --arch=x86
