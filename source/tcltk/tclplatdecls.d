/**
 * D bindings to Tcl/Tk
 *
 * License:
 *     MIT. See LICENSE for full details.
 */
module tcltk.tclplatdecls;

import tcltk.tcl;

version (Windows)
{
	import core.stdc.stddef : wchar_t;
}

version (OSX)
{
	import tcltk.tcl : Tcl_Interp;
}

version (Windows)
{
	// wchar_t is used here in lieu of TCHAR.
	extern(C) const(wchar_t)* Tcl_WinUtfToTChar(const(char)* str, int len, Tcl_DString* dsPtr) nothrow;
	extern(C) const(char)* Tcl_WinTCharToUtf(const(wchar_t)* str, int len, Tcl_DString* dsPtr) nothrow;
}

version (OSX)
{
	extern(C) int Tcl_MacOSXOpenBundleResources(Tcl_Interp* interp, const(char)* bundleName, int hasResourceFile, int maxPathLen, const(char)* libraryPath) nothrow;
	extern(C) int Tcl_MacOSXOpenVersionedBundleResources(Tcl_Interp* interp, const(char)* bundleName, const(char)* bundleVersion, int hasResourceFile, int maxPathLen, const(char)* libraryPath) nothrow;
}

struct TclPlatStubs
{
	int magic;

	struct TclPlatStubHooks;
	TclPlatStubHooks* hooks;

	version (Windows)
	{
		// wchar_t is used here in lieu of TCHAR.
		extern(C) const(wchar_t)* function(const(char)* str, int len, Tcl_DString* dsPtr) nothrow tcl_WinUtfToTChar;
		extern(C) const(char)* function(const(wchar_t)* str, int len, Tcl_DString* dsPtr) nothrow tcl_WinTCharToUtf;
	}

	version (OSX)
	{
		extern(C) int function(Tcl_Interp* interp, const(char)* bundleName, int hasResourceFile, int maxPathLen, const(char)* libraryPath) nothrow tcl_MacOSXOpenBundleResources;
		extern(C) int function(Tcl_Interp* interp, const(char)* bundleName, const(char)* bundleVersion, int hasResourceFile, int maxPathLen, const(char)* libraryPath) nothrow tcl_MacOSXOpenVersionedBundleResources;
	}
}

extern(C) shared TclPlatStubs* tclPlatStubsPtr;
