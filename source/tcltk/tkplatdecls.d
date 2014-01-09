/**
 * D bindings to Tcl/Tk
 *
 * License:
 *     MIT. See LICENSE for full details.
 */
module tcltk.tkplatdecls;

import core.stdc.config;
import core.sys.windows.windows;
import x11.X;
import tcltk.tk;

/*
 * Exported function declarations:
 */
version(Windows)
{
	extern(C) Window Tk_AttachHWND(Tk_Window tkwin, HWND hwnd) nothrow;
	extern(C) HINSTANCE Tk_GetHINSTANCE() nothrow;
	extern(C) HWND Tk_GetHWND(Window window) nothrow;
	extern(C) Tk_Window Tk_HWNDToWindow(HWND hwnd) nothrow;
	extern(C) void Tk_PointerEvent(HWND hwnd, int x, int y) nothrow;
	extern(C) int Tk_TranslateWinEvent(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, LRESULT* result) nothrow;
}

version(OSX)
{
	extern(C) void Tk_MacOSXTurnOffMenus();
	extern(C) void Tk_MacOSXTkOwnsCursor(int tkOwnsIt);
	extern(C) void TkMacOSXInitMenus(Tcl_Interp* interp);
	extern(C) void TkMacOSXInitAppleEvents(Tcl_Interp* interp);
	extern(C) void TkGenWMConfigureEvent(Tk_Window tkwin, int x, int y, int width, int height, int flags);
	extern(C) void TkMacOSXInvalClipRgns(Tk_Window tkwin);
	extern(C) void Tk_MacOSXSetupTkNotifier();
	extern(C) int Tk_MacOSXIsAppInFront();
}

struct TkPlatStubHooks;

struct TkPlatStubs
{
	int magic;
	TkPlatStubHooks* hooks;

	version(Windows)
	{
		extern(C) Window function(Tk_Window tkwin, HWND hwnd) nothrow tk_AttachHWND;
		extern(C) HINSTANCE function() nothrow tk_GetHINSTANCE;
		extern(C) HWND function(Window window) nothrow tk_GetHWND;
		extern(C) Tk_Window function(HWND hwnd) nothrow tk_HWNDToWindow;
		extern(C) void function(HWND hwnd, int x, int y) nothrow tk_PointerEvent;
		extern(C) int function(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam, LRESULT* result) nothrow tk_TranslateWinEvent;
	}

	version(OSX)
	{
		extern(C) void function() nothrow tk_MacOSXTurnOffMenus;
		extern(C) void function(int tkOwnsIt) nothrow tk_MacOSXTkOwnsCursor;
		extern(C) void function(Tcl_Interp* interp) nothrow tkMacOSXInitMenus;
		extern(C) void function(Tcl_Interp* interp) nothrow tkMacOSXInitAppleEvents;
		extern(C) void function(Tk_Window tkwin, int x, int y, int width, int height, int flags) nothrow tkGenWMConfigureEvent;
		extern(C) void function(Tk_Window tkwin) nothrow tkMacOSXInvalClipRgns;
		extern(C) void function() nothrow tk_MacOSXSetupTkNotifier;
		extern(C) int function() nothrow tk_MacOSXIsAppInFront;
	}
}

extern(C) shared TkPlatStubs* tkPlatStubsPtr;
