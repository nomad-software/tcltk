#tcltk
**Bindings to Tcl/Tk for the D programming language**

---

## Supported platforms
These bindings have been developed with DMD v2.064.2. Other compilers have not been tested but should build fine.

### Linux
Should build just fine.

### Mac OSX
Should build just fine.

### Windows
[ActiveState ActiveTcl](http://www.activestate.com/activetcl) must be installed.

#### 32bit DMD compiler on 64bit Windows
If compiling using the 32bit DMD compiler on Windows 64bit then you must pass the following option when building using dub:

    --arch=x86
