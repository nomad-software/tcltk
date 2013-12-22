#tcltk
**D bindings to Tcl/Tk**

---

## Supported platforms
These bindings have only been tested on Linux, developed with DMD v2.064.2. Other compilers have not been tested but should build fine.

## Compiler flags

### Required
You will need to pass linker flags to the compiler to link to the neccessary Tcl and Tk libraries.

### Notes

### Building with dub
To build tcltk as a static library using [dub](https://github.com/rejectedsoftware/dub) use the following command.

	dub build --config=library
