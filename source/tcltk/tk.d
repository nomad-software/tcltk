/**
 * D bindings to Tcl/Tk
 *
 * License:
 *     MIT. See LICENSE for full details.
 */
module tcltk.tk;

import core.stdc.config;
import x11.X;
import x11.Xlib;

public import tcltk.tcl;

static if (TCL_MAJOR_VERSION != 8 || TCL_MINOR_VERSION != 5)
{
	static assert(false, "Error Tk 8.5 must be compiled with tcl.h from Tcl 8.5");
}

/*
 * When version numbers change here, you must also go into the following files
 * and update the version numbers:
 *
 * library/tk.tcl	(2 LOC patch)
 * unix/configure.in	(2 LOC Major, 2 LOC minor, 1 LOC patch)
 * win/configure.in	(as above)
 * README		(sections 0 and 1)
 * macosx/Wish.xcode/project.pbxproj (not patchlevel) 1 LOC
 * macosx/Wish-Common.xcconfig (not patchlevel) 1 LOC
 * win/README		(not patchlevel)
 * unix/README		(not patchlevel)
 * unix/tk.spec		(1 LOC patch)
 * win/tcl.m4		(not patchlevel)
 *
 * You may also need to update some of these files when the numbers change for
 * the version of Tcl that this release of Tk is compiled against.
 */
enum TK_MAJOR_VERSION  = 8;
enum TK_MINOR_VERSION  = 5;
enum TK_RELEASE_LEVEL  = TCL_FINAL_RELEASE;
enum TK_RELEASE_SERIAL = 11;
enum TK_VERSION        = "8.5";
enum TK_PATCH_LEVEL    = "8.5.11";

/*
 * Dummy types that are used by clients:
 */
struct Tk_BindingTable_;
alias Tk_BindingTable = Tk_BindingTable_*;
struct Tk_Canvas_;
alias Tk_Canvas = Tk_Canvas_*;
struct Tk_Cursor_;
alias Tk_Cursor = Tk_Cursor_*;
struct Tk_ErrorHandler_;
alias Tk_ErrorHandler = Tk_ErrorHandler_*;
struct Tk_Font_;
alias Tk_Font = Tk_Font_*;
struct Tk_Image_;
alias Tk_Image = Tk_Image_*;
struct Tk_ImageMaster_;
alias Tk_ImageMaster = Tk_ImageMaster_*;
struct Tk_OptionTable_;
alias Tk_OptionTable = Tk_OptionTable_*;
struct Tk_PostscriptInfo_;
alias Tk_PostscriptInfo = Tk_PostscriptInfo_*;
struct Tk_TextLayout_;
alias Tk_TextLayout = Tk_TextLayout_*;
struct Tk_Window_;
alias Tk_Window = Tk_Window_*;
struct Tk_3DBorder_;
alias Tk_3DBorder = Tk_3DBorder_*;
struct Tk_Style_;
alias Tk_Style = Tk_Style_*;
struct Tk_StyleEngine_;
alias Tk_StyleEngine = Tk_StyleEngine_*;
struct Tk_StyledElement_;
alias Tk_StyledElement = Tk_StyledElement_*;

/*
 * Additional types exported to clients.
 */
alias Tk_Uid = const(char)*;

/*
 * The enum below defines the valid types for Tk configuration options as
 * implemented by Tk_InitOptions, Tk_SetOptions, etc.
 */
enum Tk_OptionType
{
    TK_OPTION_BOOLEAN,
    TK_OPTION_INT,
    TK_OPTION_DOUBLE,
    TK_OPTION_STRING,
    TK_OPTION_STRING_TABLE,
    TK_OPTION_COLOR,
    TK_OPTION_FONT,
    TK_OPTION_BITMAP,
    TK_OPTION_BORDER,
    TK_OPTION_RELIEF,
    TK_OPTION_CURSOR,
    TK_OPTION_JUSTIFY,
    TK_OPTION_ANCHOR,
    TK_OPTION_SYNONYM,
    TK_OPTION_PIXELS,
    TK_OPTION_WINDOW,
    TK_OPTION_END,
    TK_OPTION_CUSTOM,
    TK_OPTION_STYLE,
}

/*
 * Structures of the following type are used by widgets to specify their
 * configuration options. Typically each widget has a static array of these
 * structures, where each element of the array describes a single
 * configuration option. The array is passed to Tk_CreateOptionTable.
 */
struct Tk_OptionSpec
{
	/* Type of option, such as TK_OPTION_COLOR;
	 * see definitions above. Last option in table
	 * must have type TK_OPTION_END. */
	Tk_OptionType type;

	/* Name used to specify option in Tcl
	 * commands. */
	const(char)* optionName;

	/* Name for option in option database. */
	const(char)* dbName;

	/* Class for option in database. */
	const(char)* dbClass;

	/* Default value for option if not specified
	 * in command line, the option database, or
	 * the system. */
	const(char)* defValue;

	/* Where in record to store a Tcl_Obj * that
	 * holds the value of this option, specified
	 * as an offset in bytes from the start of the
	 * record. Use the Tk_Offset macro to generate
	 * values for this. -1 means don't store the
	 * Tcl_Obj in the record. */
	int objOffset;

	/* Where in record to store the internal
	 * representation of the value of this option,
	 * such as an int or XColor *. This field is
	 * specified as an offset in bytes from the
	 * start of the record. Use the Tk_Offset
	 * macro to generate values for it. -1 means
	 * don't store the internal representation in
	 * the record. */
	int internalOffset;

	/* Any combination of the values defined
	 * below. */
	int flags;

	/* An alternate place to put option-specific
	 * data. Used for the monochrome default value
	 * for colors, etc. */
	ClientData clientData;

	/* An arbitrary bit mask defined by the class
	 * manager; typically bits correspond to
	 * certain kinds of options such as all those
	 * that require a redisplay when they change.
	 * Tk_SetOptions returns the bit-wise OR of
	 * the typeMasks of all options that were
	 * changed. */
	int typeMask;
}

/*
 * Flag values for Tk_OptionSpec structures. These flags are shared by
 * Tk_ConfigSpec structures, so be sure to coordinate any changes carefully.
 */
enum TK_OPTION_NULL_OK          = (1 << 0);
enum TK_OPTION_DONT_SET_DEFAULT = (1 << 3);

/*
 * The following structure and function types are used by TK_OPTION_CUSTOM
 * options; the structure holds pointers to the functions needed by the Tk
 * option config code to handle a custom option.
 */
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, Tk_Window tkwin, Tcl_Obj** value, const(char)* widgRec, int offset, const(char)* saveInternalPtr, int flags) nothrow Tk_CustomOptionSetProc;
alias extern(C) Tcl_Obj* function(ClientData clientData, Tk_Window tkwin, const(char)* widgRec, int offset) nothrow Tk_CustomOptionGetProc;
alias extern(C) void function(ClientData clientData, Tk_Window tkwin, const(char)* internalPtr, const(char)* saveInternalPtr) nothrow Tk_CustomOptionRestoreProc;
alias extern(C) void function(ClientData clientData, Tk_Window tkwin, const(char)* internalPtr) nothrow Tk_CustomOptionFreeProc;

struct Tk_ObjCustomOption
{
	/* Name of the custom option. */
	const(char)* name;

	/* Function to use to set a record's option
	 * value from a Tcl_Obj */
	Tk_CustomOptionSetProc setProc;

	/* Function to use to get a Tcl_Obj
	 * representation from an internal
	 * representation of an option. */
	Tk_CustomOptionGetProc getProc;

	/* Function to use to restore a saved value
	 * for the internal representation. */
	Tk_CustomOptionRestoreProc restoreProc;

	/* Function to use to free the internal
	 * representation of an option. */
	Tk_CustomOptionFreeProc freeProc;

	/* Arbitrary one-word value passed to the
	 * handling procs. */
	ClientData clientData;
}

/*
 * Macro to use to fill in "offset" fields of the Tk_OptionSpec structure.
 * Computes number of bytes from beginning of structure to a given field.
 */
int Tk_Offset(Type, string field)()
{
	return mixin(Type.stringof ~ ".init." ~ field ~ ".offsetof");
}

/*
 * The following two structures are used for error handling. When config
 * options are being modified, the old values are saved in a Tk_SavedOptions
 * structure. If an error occurs, then the contents of the structure can be
 * used to restore all of the old values. The contents of this structure are
 * for the private use Tk. No-one outside Tk should ever read or write any of
 * the fields of these structures.
 */
struct TkOption;
struct Tk_SavedOption
{
	/* Points to information that describes the
	 * option. */
	TkOption* optionPtr;

	/* The old value of the option, in the form of
	 * a Tcl object; may be NULL if the value was
	 * not saved as an object. */
	Tcl_Obj* valuePtr;

	/* The old value of the option, in some
	 * internal representation such as an int or
	 * (XColor *). Valid only if the field
	 * optionPtr->specPtr->objOffset is < 0. The
	 * space must be large enough to accommodate a
	 * double, a long, or a pointer; right now it
	 * looks like a double (i.e., 8 bytes) is big
	 * enough. Also, using a double guarantees
	 * that the field is properly aligned for
	 * storing large values. */
	double internalForm;
}

version(TCL_MEM_DEBUG)
{
	enum TK_NUM_SAVED_OPTIONS = 2;
}
else
{
	enum TK_NUM_SAVED_OPTIONS = 20;
}

struct Tk_SavedOptions
{
	/* The data structure in which to restore
	 * configuration options. */
	const(char)* recordPtr;

	/* Window associated with recordPtr; needed to
	 * restore certain options. */
	Tk_Window tkwin;

	/* The number of valid items in items field. */
	int numItems;

	/* Items used to hold old values. */
	Tk_SavedOption[TK_NUM_SAVED_OPTIONS] items;

	/* Points to next structure in list; needed if
	 * too many options changed to hold all the
	 * old values in a single structure. NULL
	 * means no more structures. */
	Tk_SavedOptions* nextPtr;
}

/*
 * Structure used to describe application-specific configuration options:
 * indicates procedures to call to parse an option and to return a text string
 * describing an option. THESE ARE DEPRECATED; PLEASE USE THE NEW STRUCTURES
 * LISTED ABOVE.
 */

/*
 * This is a temporary flag used while tkObjConfig and new widgets are in
 * development.
 */
enum __NO_OLD_CONFIG = false;

static if (!__NO_OLD_CONFIG)
{
	alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, Tk_Window tkwin, const(char)* value, const(char)* widgRec, int offset) nothrow Tk_OptionParseProc;
	alias extern(C) const(char)* function(ClientData clientData, Tk_Window tkwin, const(char)* widgRec, int offset, Tcl_FreeProc* freeProcPtr) nothrow Tk_OptionPrintProc;

	struct Tk_CustomOption
	{
		/* Procedure to call to parse an option and
		 * store it in converted form. */
		Tk_OptionParseProc parseProc;

		/* Procedure to return a printable string
		 * describing an existing option. */
		Tk_OptionPrintProc printProc;

		/* Arbitrary one-word value used by option
		 * parser: passed to parseProc and
		 * printProc. */
		ClientData clientData;
	}

	/*
	 * Structure used to specify information for Tk_ConfigureWidget. Each
	 * structure gives complete information for one option, including how the
	 * option is specified on the command line, where it appears in the option
	 * database, etc.
	 */
	struct Tk_ConfigSpec
	{
		/* Type of option, such as TK_CONFIG_COLOR;
		 * see definitions below. Last option in table
		 * must have type TK_CONFIG_END. */
		int type;

		/* Switch used to specify option in argv. NULL
		 * means this spec is part of a group. */
		const(char)* argvName;

		/* Name for option in option database. */
		Tk_Uid dbName;

		/* Class for option in database. */
		Tk_Uid dbClass;

		/* Default value for option if not specified
		 * in command line or database. */
		Tk_Uid defValue;

		/* Where in widget record to store value; use
		 * Tk_Offset macro to generate values for
		 * this. */
		int offset;

		/* Any combination of the values defined
		 * below; other bits are used internally by
		 * tkConfig.c. */
		int specFlags;

		/* If type is TK_CONFIG_CUSTOM then this is a
		 * pointer to info about how to parse and
		 * print the option. Otherwise it is
		 * irrelevant. */
		Tk_CustomOption* customPtr;
	}

	/*
	 * Type values for Tk_ConfigSpec structures. See the user documentation for
	 * details.
	 */
	enum Tk_ConfigTypes
	{
		TK_CONFIG_BOOLEAN,
		TK_CONFIG_INT,
		TK_CONFIG_DOUBLE,
		TK_CONFIG_STRING,
		TK_CONFIG_UID,
		TK_CONFIG_COLOR,
		TK_CONFIG_FONT,
		TK_CONFIG_BITMAP,
		TK_CONFIG_BORDER,
		TK_CONFIG_RELIEF,
		TK_CONFIG_CURSOR,
		TK_CONFIG_ACTIVE_CURSOR,
		TK_CONFIG_JUSTIFY,
		TK_CONFIG_ANCHOR,
		TK_CONFIG_SYNONYM,
		TK_CONFIG_CAP_STYLE,
		TK_CONFIG_JOIN_STYLE,
		TK_CONFIG_PIXELS,
		TK_CONFIG_MM,
		TK_CONFIG_WINDOW,
		TK_CONFIG_CUSTOM,
		TK_CONFIG_END,
	}

	/*
	 * Possible values for flags argument to Tk_ConfigureWidget:
	 */
	enum TK_CONFIG_ARGV_ONLY = 1;
	enum TK_CONFIG_OBJS      = 0x80;

	/*
	 * Possible flag values for Tk_ConfigSpec structures. Any bits at or above
	 * TK_CONFIG_USER_BIT may be used by clients for selecting certain entries.
	 * Before changing any values here, coordinate with tkOldConfig.c
	 * (internal-use-only flags are defined there).
	 */
	enum TK_CONFIG_NULL_OK          = (1 << 0);
	enum TK_CONFIG_COLOR_ONLY       = (1 << 1);
	enum TK_CONFIG_MONO_ONLY        = (1 << 2);
	enum TK_CONFIG_DONT_SET_DEFAULT = (1 << 3);
	enum TK_CONFIG_OPTION_SPECIFIED = (1 << 4);
	enum TK_CONFIG_USER_BIT         = 0x100;
}

/*
 * Structure used to specify how to handle argv options.
 */
struct Tk_ArgvInfo
{
	/* The key string that flags the option in the
	 * argv array. */
	const(char)* key;

	/* Indicates option type; see below. */
	int type;

	/* Value to be used in setting dst; usage
	 * depends on type. */
	const(char)* src;

	/* Address of value to be modified; usage
	 * depends on type. */
	const(char)* dst;

	/* Documentation message describing this
	 * option. */
	const(char)* help;
}

/*
 * Legal values for the type field of a Tk_ArgvInfo: see the user
 * documentation for details.
 */
enum TK_ARGV_CONSTANT          = 15;
enum TK_ARGV_INT               = 16;
enum TK_ARGV_STRING            = 17;
enum TK_ARGV_UID               = 18;
enum TK_ARGV_REST              = 19;
enum TK_ARGV_FLOAT             = 20;
enum TK_ARGV_FUNC              = 21;
enum TK_ARGV_GENFUNC           = 22;
enum TK_ARGV_HELP              = 23;
enum TK_ARGV_CONST_OPTION      = 24;
enum TK_ARGV_OPTION_VALUE      = 25;
enum TK_ARGV_OPTION_NAME_VALUE = 26;
enum TK_ARGV_END               = 27;

/*
 * Flag bits for passing to Tk_ParseArgv:
 */
enum TK_ARGV_NO_DEFAULTS         = 0x1;
enum TK_ARGV_NO_LEFTOVERS        = 0x2;
enum TK_ARGV_NO_ABBREV           = 0x4;
enum TK_ARGV_DONT_SKIP_FIRST_ARG = 0x8;

/*
 * Enumerated type for describing actions to be taken in response to a
 * restrictProc established by Tk_RestrictEvents.
 */
enum Tk_RestrictAction
{
	TK_DEFER_EVENT,
	TK_PROCESS_EVENT,
	TK_DISCARD_EVENT,
}

/*
 * Priority levels to pass to Tk_AddOption:
 */
enum TK_WIDGET_DEFAULT_PRIO = 20;
enum TK_STARTUP_FILE_PRIO   = 40;
enum TK_USER_DEFAULT_PRIO   = 60;
enum TK_INTERACTIVE_PRIO    = 80;
enum TK_MAX_PRIO            = 100;

/*
 * Relief values returned by Tk_GetRelief:
 */
enum TK_RELIEF_NULL   = -1;
enum TK_RELIEF_FLAT   = 0;
enum TK_RELIEF_GROOVE = 1;
enum TK_RELIEF_RAISED = 2;
enum TK_RELIEF_RIDGE  = 3;
enum TK_RELIEF_SOLID  = 4;
enum TK_RELIEF_SUNKEN = 5;

/*
 * "Which" argument values for Tk_3DBorderGC:
 */
enum TK_3D_FLAT_GC  = 1;
enum TK_3D_LIGHT_GC = 2;
enum TK_3D_DARK_GC  = 3;

/*
 * Special EnterNotify/LeaveNotify "mode" for use in events generated by
 * tkShare.c. Pick a high enough value that it's unlikely to conflict with
 * existing values (like NotifyNormal) or any new values defined in the
 * future.
 */
enum TK_NOTIFY_SHARE = 20;

/*
 * Enumerated type for describing a point by which to anchor something:
 */
enum  Tk_Anchor
{
	TK_ANCHOR_N,
	TK_ANCHOR_NE,
	TK_ANCHOR_E,
	TK_ANCHOR_SE,
	TK_ANCHOR_S,
	TK_ANCHOR_SW,
	TK_ANCHOR_W,
	TK_ANCHOR_NW,
	TK_ANCHOR_CENTER,
}

/*
 * Enumerated type for describing a style of justification:
 */
enum Tk_Justify
{
	TK_JUSTIFY_LEFT,
	TK_JUSTIFY_RIGHT,
	TK_JUSTIFY_CENTER,
}

/*
 * The following structure is used by Tk_GetFontMetrics() to return
 * information about the properties of a Tk_Font.
 */
struct Tk_FontMetrics
{
	/* The amount in pixels that the tallest
	 * letter sticks up above the baseline, plus
	 * any extra blank space added by the designer
	 * of the font. */
	int ascent;

	/* The largest amount in pixels that any
	 * letter sticks below the baseline, plus any
	 * extra blank space added by the designer of
	 * the font. */
	int descent;

	/* The sum of the ascent and descent. How far
	 * apart two lines of text in the same font
	 * should be placed so that none of the
	 * characters in one line overlap any of the
	 * characters in the other line. */
	int linespace;
}

/*
 * Flags passed to Tk_MeasureChars:
 */
enum TK_WHOLE_WORDS  = 1;
enum TK_AT_LEAST_ONE = 2;
enum TK_PARTIAL_OK   = 4;

/*
 * Flags passed to Tk_ComputeTextLayout:
 */
enum TK_IGNORE_TABS     = 8;
enum TK_IGNORE_NEWLINES = 16;

/*
 * Widget class procedures used to implement platform specific widget
 * behavior.
 */

alias extern(C) Window function(Tk_Window tkwin, Window parent, ClientData instanceData) nothrow Tk_ClassCreateProc;
alias extern(C) void function(ClientData instanceData) nothrow Tk_ClassWorldChangedProc;
alias extern(C) void function(Tk_Window tkwin, XEvent* eventPtr) nothrow Tk_ClassModalProc;

struct Tk_ClassProcs
{
	uint size;

	/* Procedure to invoke when the widget needs
	 * to respond in some way to a change in the
	 * world (font changes, etc.) */
	Tk_ClassWorldChangedProc worldChangedProc;

	/* Procedure to invoke when the platform-
	 * dependent window needs to be created. */
	Tk_ClassCreateProc createProc;

	/* Procedure to invoke after all bindings on a
	 * widget have been triggered in order to
	 * handle a modal loop. */
	Tk_ClassModalProc modalProc;
}

/*
 * Each geometry manager (the packer, the placer, etc.) is represented by a
 * structure of the following form, which indicates procedures to invoke in
 * the geometry manager to carry out certain functions.
 */
alias extern(C) void function(ClientData clientData, Tk_Window tkwin) nothrow Tk_GeomRequestProc;
alias extern(C) void function(ClientData clientData, Tk_Window tkwin) nothrow Tk_GeomLostSlaveProc;

struct Tk_GeomMgr
{
	/* Name of the geometry manager (command used
	 * to invoke it, or name of widget class that
	 * allows embedded widgets). */
	const(char)* name;

	/* Procedure to invoke when a slave's
	 * requested geometry changes. */
	Tk_GeomRequestProc requestProc;

	/* Procedure to invoke when a slave is taken
	 * away from one geometry manager by another.
	 * NULL means geometry manager doesn't care
	 * when slaves are lost. */
	Tk_GeomLostSlaveProc lostSlaveProc;
}

/*
 * Result values returned by Tk_GetScrollInfo:
 */
enum TK_SCROLL_MOVETO = 1;
enum TK_SCROLL_PAGES  = 2;
enum TK_SCROLL_UNITS  = 3;
enum TK_SCROLL_ERROR  = 4;

/*
 *---------------------------------------------------------------------------
 *
 * Extensions to the X event set
 *
 *---------------------------------------------------------------------------
 */
enum VirtualEvent     = (MappingNotify + 1);
enum ActivateNotify   = (MappingNotify + 2);
enum DeactivateNotify = (MappingNotify + 3);
enum MouseWheelEvent  = (MappingNotify + 4);
enum TK_LASTEVENT     = (MappingNotify + 5);
enum MouseWheelMask   = (1L << 28);
enum ActivateMask     = (1L << 29);
enum VirtualEventMask = (1L << 30);

/*
 * A virtual event shares most of its fields with the XKeyEvent and
 * XButtonEvent structures. 99% of the time a virtual event will be an
 * abstraction of a key or button event, so this structure provides the most
 * information to the user. The only difference is the changing of the detail
 * field for a virtual event so that it holds the name of the virtual event
 * being triggered.
 *
 * When using this structure, you should ensure that you zero out all the
 * fields first using memset() or bzero().
 */
struct XVirtualEvent
{
	int type;

	/* # of last request processed by server. */
	c_ulong serial;

	/* True if this came from a SendEvent
	 * request. */
	bool send_event;

	/* Display the event was read from. */
	Display* display;

	/* Window on which event was requested. */
	Window event;

	/* Root window that the event occured on. */
	Window root;

	/* Child window. */
	Window subwindow;

	/* Milliseconds. */
	Time time;

	/* Pointer x, y coordinates in event
	 * window. */
	int x, y;

	/* Coordinates relative to root. */
	int x_root, y_root;

	/* Key or button mask */
	uint state;

	/* Name of virtual event. */
	Tk_Uid name;

	/* Same screen flag. */
	bool same_screen;

	/* Application-specific data reference; Tk
	 * will decrement the reference count *once*
	 * when it has finished processing the
	 * event. */
	Tcl_Obj* user_data;
}

struct XActivateDeactivateEvent
{
	int type;

	/* # of last request processed by server. */
	c_ulong serial;

	/* True if this came from a SendEvent
	 * request. */
	bool send_event;

	/* Display the event was read from. */
	Display* display;

	/* Window in which event occurred. */
	Window window;
}

alias XActivateEvent   = XActivateDeactivateEvent;
alias XDeactivateEvent = XActivateDeactivateEvent;

/*
 * The structure below is needed by the macros below so that they can access
 * the fields of a Tk_Window. The fields not needed by the macros are declared
 * as "dummyX". The structure has its own type in order to prevent apps from
 * accessing Tk_Window fields except using official macros. WARNING!! The
 * structure definition must be kept consistent with the TkWindow structure in
 * tkInt.h. If you change one, then change the other. See the declaration in
 * tkInt.h for documentation on what the fields are used for internally.
 */
struct Tk_FakeWin
{
    Display* display;
    void* dummy1; /* dispPtr */
    int screenNum;
    Visual* visual;
    int depth;
    Window window;
    void* dummy2; /* childList */
    void* dummy3; /* lastChildPtr */
    Tk_Window parentPtr; /* parentPtr */
    void* dummy4; /* nextPtr */
    void* dummy5; /* mainPtr */
    const(char)* pathName;
    Tk_Uid nameUid;
    Tk_Uid classUid;
    XWindowChanges changes;
    uint dummy6; /* dirtyChanges */
    XSetWindowAttributes atts;
    c_ulong dummy7; /* dirtyAtts */
    uint flags;
    void* dummy8; /* handlerList */
    ClientData* dummy10; /* tagPtr */
    int dummy11; /* numTags */
    int dummy12; /* optionLevel */
    void* dummy13; /* selHandlerList */
    void* dummy14; /* geomMgrPtr */
    ClientData dummy15; /* geomData */
    int reqWidth;
	int reqHeight;
    int internalBorderLeft;
    void* dummy16; /* wmInfoPtr */
    void* dummy17; /* classProcPtr */
    ClientData dummy18; /* instanceData */
    void* dummy19; /* privatePtr */
    int internalBorderRight;
    int internalBorderTop;
    int internalBorderBottom;
    int minReqWidth;
    int minReqHeight;
}

/*
 * Flag values for TkWindow (and Tk_FakeWin) structures are:
 *
 * TK_MAPPED:			1 means window is currently mapped,
 *				0 means unmapped.
 * TK_TOP_LEVEL:		1 means this is a top-level widget.
 * TK_ALREADY_DEAD:		1 means the window is in the process of
 *				being destroyed already.
 * TK_NEED_CONFIG_NOTIFY:	1 means that the window has been reconfigured
 *				before it was made to exist. At the time of
 *				making it exist a ConfigureNotify event needs
 *				to be generated.
 * TK_GRAB_FLAG:		Used to manage grabs. See tkGrab.c for details
 * TK_CHECKED_IC:		1 means we've already tried to get an input
 *				context for this window; if the ic field is
 *				NULL it means that there isn't a context for
 *				the field.
 * TK_DONT_DESTROY_WINDOW:	1 means that Tk_DestroyWindow should not
 *				invoke XDestroyWindow to destroy this widget's
 *				X window. The flag is set when the window has
 *				already been destroyed elsewhere (e.g. by
 *				another application) or when it will be
 *				destroyed later (e.g. by destroying its parent)
 * TK_WM_COLORMAP_WINDOW:	1 means that this window has at some time
 *				appeared in the WM_COLORMAP_WINDOWS property
 *				for its toplevel, so we have to remove it from
 *				that property if the window is deleted and the
 *				toplevel isn't.
 * TK_EMBEDDED:			1 means that this window (which must be a
 *				toplevel) is not a free-standing window but
 *				rather is embedded in some other application.
 * TK_CONTAINER:		1 means that this window is a container, and
 *				that some other application (either in this
 *				process or elsewhere) may be embedding itself
 *				inside the window.
 * TK_BOTH_HALVES:		1 means that this window is used for
 *				application embedding (either as container or
 *				embedded application), and both the containing
 *				and embedded halves are associated with
 *				windows in this particular process.
 * TK_DEFER_MODAL:		1 means that this window has deferred a modal
 *				loop until all of the bindings for the current
 *				event have been invoked.
 * TK_WRAPPER:			1 means that this window is the extra wrapper
 *				window created around a toplevel to hold the
 *				menubar under Unix. See tkUnixWm.c for more
 *				information.
 * TK_REPARENTED:		1 means that this window has been reparented
 *				so that as far as the window system is
 *				concerned it isn't a child of its Tk parent.
 *				Initially this is used only for special Unix
 *				menubar windows.
 * TK_ANONYMOUS_WINDOW:		1 means that this window has no name, and is
 *				thus not accessible from Tk.
 * TK_HAS_WRAPPER		1 means that this window has a wrapper window
 * TK_WIN_MANAGED		1 means that this window is a child of the root
 *				window, and is managed by the window manager.
 * TK_TOP_HIERARCHY		1 means this window is at the top of a physical
 *				window hierarchy within this process, i.e. the
 *				window's parent either doesn't exist or is not
 *				owned by this Tk application.
 * TK_PROP_PROPCHANGE		1 means that PropertyNotify events in the
 *				window's children should propagate up to this
 *				window.
 * TK_WM_MANAGEABLE		1 marks a window as capable of being converted
 *				into a toplevel using [wm manage].
 */
enum TK_MAPPED              = 1;
enum TK_TOP_LEVEL           = 2;
enum TK_ALREADY_DEAD        = 4;
enum TK_NEED_CONFIG_NOTIFY  = 8;
enum TK_GRAB_FLAG           = 0x10;
enum TK_CHECKED_IC          = 0x20;
enum TK_DONT_DESTROY_WINDOW = 0x40;
enum TK_WM_COLORMAP_WINDOW  = 0x80;
enum TK_EMBEDDED            = 0x100;
enum TK_CONTAINER           = 0x200;
enum TK_BOTH_HALVES         = 0x400;
enum TK_DEFER_MODAL         = 0x800;
enum TK_WRAPPER             = 0x1000;
enum TK_REPARENTED          = 0x2000;
enum TK_ANONYMOUS_WINDOW    = 0x4000;
enum TK_HAS_WRAPPER         = 0x8000;
enum TK_WIN_MANAGED         = 0x10000;
enum TK_TOP_HIERARCHY       = 0x20000;
enum TK_PROP_PROPCHANGE     = 0x40000;
enum TK_WM_MANAGEABLE       = 0x80000;

/*
 *--------------------------------------------------------------
 *
 * Macros for querying Tk_Window structures. See the manual entries for
 * documentation.
 *
 *--------------------------------------------------------------
 */
Display* Tk_Display(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).display;
}

int Tk_ScreenNumber(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).screenNum;
}

Screen* Tk_Screen(Tk_Window tkwin)
{
	return ScreenOfDisplay(Tk_Display(tkwin), Tk_ScreenNumber(tkwin));
}

int Tk_Depth(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).depth;
}

Visual* Tk_Visual(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).visual;
}

Window Tk_WindowId(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).window;
}

const(char)* Tk_PathName(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).pathName;
}

Tk_Uid Tk_Name(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).nameUid;
}

Tk_Uid Tk_Class(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).classUid;
}

int Tk_X(Tk_Window tkwin)
{
	return Tk_Changes(tkwin).x;
}

int Tk_Y(Tk_Window tkwin)
{
	return Tk_Changes(tkwin).y;
}

int Tk_Width(Tk_Window tkwin)
{
	return Tk_Changes(tkwin).width;
}

int Tk_Height(Tk_Window tkwin)
{
	return Tk_Changes(tkwin).height;
}

XWindowChanges Tk_Changes(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).changes;
}

XSetWindowAttributes Tk_Attributes(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).atts;
}

uint Tk_IsEmbedded(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_EMBEDDED;
}

uint Tk_IsContainer(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_CONTAINER;
}

uint Tk_IsMapped(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_MAPPED;
}

uint Tk_IsTopLevel(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_TOP_LEVEL;
}

uint Tk_HasWrapper(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_HAS_WRAPPER;
}

uint Tk_WinManaged(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_WIN_MANAGED;
}

uint Tk_TopWinHierarchy(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_TOP_HIERARCHY;
}

uint Tk_IsManageable(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).flags & TK_WM_MANAGEABLE;
}

int Tk_ReqWidth(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).reqWidth;
}

int Tk_ReqHeight(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).reqHeight;
}

deprecated int Tk_InternalBorderWidth(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).internalBorderLeft;
}

int Tk_InternalBorderLeft(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).internalBorderLeft;
}

int Tk_InternalBorderRight(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).internalBorderRight;
}

int Tk_InternalBorderTop(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).internalBorderTop;
}

int Tk_InternalBorderBottom(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).internalBorderBottom;
}

int Tk_MinReqWidth(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).minReqWidth;
}

int Tk_MinReqHeight(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).minReqHeight;
}

Tk_Window Tk_Parent(Tk_Window tkwin)
{
	return (*(cast(Tk_FakeWin*)tkwin)).parentPtr;
}

Colormap Tk_Colormap(Tk_Window tkwin)
{
	return Tk_Attributes(tkwin).colormap;
}

/*
 *--------------------------------------------------------------
 *
 * Procedure prototypes and structures used for defining new canvas items:
 *
 *--------------------------------------------------------------
 */
enum Tk_State
{
    TK_STATE_NULL = -1,
	TK_STATE_ACTIVE,
	TK_STATE_DISABLED,
    TK_STATE_NORMAL,
	TK_STATE_HIDDEN,
}

struct Tk_SmoothMethod
{
    const(char)* name;
	extern(C) int function(Tk_Canvas canvas, double* pointPtr, int numPoints, int numSteps, XPoint[] xPoints, double[] dblPoints) nothrow coordProc;
	extern(C) void function(Tcl_Interp* interp, Tk_Canvas canvas, double* coordPtr, int numPoints, int numSteps) nothrow postscriptProc;
}

enum USE_OLD_CANVAS = false;

static if (USE_OLD_CANVAS)
{
	alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, int argc, const(char)** argv) nothrow Tk_ItemCreateProc;
	alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, int argc, const(char)** argv, int flags) nothrow Tk_ItemConfigureProc;
	alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, int argc, const(char)** argv) nothrow Tk_ItemCoordProc;
}
else
{
	alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, int argc, const(Tcl_Obj*)[] objv) nothrow Tk_ItemCreateProc;
	alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, int argc, const(Tcl_Obj*)[] objv, int flags) nothrow Tk_ItemConfigureProc;
	alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, int argc, const(Tcl_Obj*)[] argv) nothrow Tk_ItemCoordProc;
}

alias extern(C) void function(Tk_Canvas canvas, Tk_Item* itemPtr, Display* display) nothrow Tk_ItemDeleteProc;
alias extern(C) void function(Tk_Canvas canvas, Tk_Item* itemPtr, Display* display, Drawable dst, int x, int y, int width, int height) nothrow Tk_ItemDisplayProc;
alias extern(C) double function(Tk_Canvas canvas, Tk_Item* itemPtr, double* pointPtr) nothrow Tk_ItemPointProc;
alias extern(C) int function(Tk_Canvas canvas, Tk_Item* itemPtr, double* rectPtr) nothrow Tk_ItemAreaProc;
alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, int prepass) nothrow Tk_ItemPostscriptProc;
alias extern(C) void function(Tk_Canvas canvas, Tk_Item* itemPtr, double originX, double originY, double scaleX, double scaleY) nothrow Tk_ItemScaleProc;
alias extern(C) void function(Tk_Canvas canvas, Tk_Item* itemPtr, double deltaX, double deltaY) nothrow Tk_ItemTranslateProc;
alias extern(C) int function(Tcl_Interp* interp, Tk_Canvas canvas, Tk_Item* itemPtr, const(char)* indexString, int* indexPtr) nothrow Tk_ItemIndexProc;
alias extern(C) void function(Tk_Canvas canvas, Tk_Item* itemPtr, int index) nothrow Tk_ItemCursorProc;
alias extern(C) int function(Tk_Canvas canvas, Tk_Item* itemPtr, int offset, const(char)* buffer, int maxBytes) nothrow Tk_ItemSelectionProc;
alias extern(C) void function(Tk_Canvas canvas, Tk_Item* itemPtr, int beforeThis, const(char)* string) nothrow Tk_ItemInsertProc;
alias extern(C) void function(Tk_Canvas canvas, Tk_Item* itemPtr, int first, int last) nothrow Tk_ItemDCharsProc;

static if (!__NO_OLD_CONFIG)
{
	/*
	 * Records of the following type are used to describe a type of item (e.g.
	 * lines, circles, etc.) that can form part of a canvas widget.
	 */
	struct Tk_ItemType
	{
		/* The name of this type of item, such as
		 * "line". */
		const(char)* name;

		/* Total amount of space needed for item's
		 * record. */
		int itemSize;

		/* Procedure to create a new item of this
		 * type. */
		Tk_ItemCreateProc createProc;

		/* Pointer to array of configuration specs for
		 * this type. Used for returning configuration
		 * info. */
		Tk_ConfigSpec* configSpecs;

		/* Procedure to call to change configuration
		 * options. */
		Tk_ItemConfigureProc configProc;

		/* Procedure to call to get and set the item's
		 * coordinates. */
		Tk_ItemCoordProc coordProc;

		/* Procedure to delete existing item of this
		 * type. */
		Tk_ItemDeleteProc deleteProc;

		/* Procedure to display items of this type. */
		Tk_ItemDisplayProc displayProc;

		/* Non-zero means displayProc should be called
		 * even when the item has been moved
		 * off-screen. */
		int alwaysRedraw;

		/* Computes distance from item to a given
		 * point. */
		Tk_ItemPointProc pointProc;

		/* Computes whether item is inside, outside,
		 * or overlapping an area. */
		Tk_ItemAreaProc areaProc;

		/* Procedure to write a Postscript description
		 * for items of this type. */
		Tk_ItemPostscriptProc postscriptProc;

		/* Procedure to rescale items of this type. */
		Tk_ItemScaleProc scaleProc;

		/* Procedure to translate items of this
		 * type. */
		Tk_ItemTranslateProc translateProc;

		/* Procedure to determine index of indicated
		 * character. NULL if item doesn't support
		 * indexing. */
		Tk_ItemIndexProc indexProc;

		/* Procedure to set insert cursor posn to just
		 * before a given position. */
		Tk_ItemCursorProc icursorProc;

		/* Procedure to return selection (in STRING
		 * format) when it is in this item. */
		Tk_ItemSelectionProc selectionProc;

		/* Procedure to insert something into an
		 * item. */
		Tk_ItemInsertProc insertProc;

		/* Procedure to delete characters from an
		 * item. */
		Tk_ItemDCharsProc dCharsProc;

		/* Used to link types together into a list. */
		Tk_ItemType* nextPtr;

		/* Reserved for future extension. */
		void* reserved1;

		/* Carefully compatible with */
		int reserved2;

		/* Jan Nijtmans dash patch */
		void* reserved3;
		void* reserved4;
	}
}
else
{
	struct Tk_ItemType;
}

/*
 * For each item in a canvas widget there exists one record with the following
 * structure. Each actual item is represented by a record with the following
 * stuff at its beginning, plus additional type-specific stuff after that.
 */
enum TK_TAG_SPACE = 3;

struct Tk_Item
{
	/* Unique identifier for this item (also
	 * serves as first tag for item). */
	int id;

	/* Next in display list of all items in this
	 * canvas. Later items in list are drawn on
	 * top of earlier ones. */
	Tk_Item* nextPtr;

	/* Built-in space for limited # of tags. */
	Tk_Uid[TK_TAG_SPACE] staticTagSpace;

	/* Pointer to array of tags. Usually points to
	 * staticTagSpace, but may point to malloc-ed
	 * space if there are lots of tags. */
	Tk_Uid* tagPtr;

	/* Total amount of tag space available at
	 * tagPtr. */
	int tagSpace;

	/* Number of tag slots actually used at
	 * *tagPtr. */
	int numTags;

	/* Table of procedures that implement this
	 * type of item. */
	Tk_ItemType* typePtr;

	/* Bounding box for item, in integer canvas
	 * units. Set by item-specific code and
	 * guaranteed to contain every pixel drawn in
	 * item. Item area includes x1 and y1 but not
	 * x2 and y2. */
	int x1;
	int y1;
	int x2;
	int y2;

	/* Previous in display list of all items in
	 * this canvas. Later items in list are drawn
	 * just below earlier ones. */
	Tk_Item* prevPtr;

	/* State of item. */
	Tk_State state;

	/* reserved for future use */
	void* reserved1;

	/* Some flags used in the canvas */
	int redraw_flags;

	/*
	 *------------------------------------------------------------------
	 * Starting here is additional type-specific stuff; see the declarations
	 * for individual types to see what is part of each type. The actual space
	 * below is determined by the "itemInfoSize" of the type's Tk_ItemType
	 * record.
	 *------------------------------------------------------------------
	 */
}

/*
 * Flag bits for canvases (redraw_flags):
 *
 * TK_ITEM_STATE_DEPENDANT -	1 means that object needs to be redrawn if the
 *				canvas state changes.
 * TK_ITEM_DONT_REDRAW - 	1 means that the object redraw is already been
 *				prepared, so the general canvas code doesn't
 *				need to do that any more.
 */
enum TK_ITEM_STATE_DEPENDANT = 1;
enum TK_ITEM_DONT_REDRAW     = 2;

/*
 * The following structure provides information about the selection and the
 * insertion cursor. It is needed by only a few items, such as those that
 * display text. It is shared by the generic canvas code and the item-specific
 * code, but most of the fields should be written only by the canvas generic
 * code.
 */
struct Tk_CanvasTextInfo
{
	/* Border and background for selected
	 * characters. Read-only to items.*/
	Tk_3DBorder selBorder;

	/* Width of border around selection. Read-only
	 * to items. */
	int selBorderWidth;

	/* Foreground color for selected text.
	 * Read-only to items. */
	XColor* selFgColorPtr;

	/* Pointer to selected item. NULL means
	 * selection isn't in this canvas. Writable by
	 * items. */
	Tk_Item* selItemPtr;

	/* Character index of first selected
	 * character. Writable by items. */
	int selectFirst;

	/* Character index of last selected character.
	 * Writable by items. */
	int selectLast;

	/* Item corresponding to "selectAnchor": not
	 * necessarily selItemPtr. Read-only to
	 * items. */
	Tk_Item* anchorItemPtr;

	/* Character index of fixed end of selection
	 * (i.e. "select to" operation will use this
	 * as one end of the selection). Writable by
	 * items. */
	int selectAnchor;

	/* Used to draw vertical bar for insertion
	 * cursor. Read-only to items. */
	Tk_3DBorder insertBorder;

	/* Total width of insertion cursor. Read-only
	 * to items. */
	int insertWidth;

	/* Width of 3-D border around insert cursor.
	 * Read-only to items. */
	int insertBorderWidth;

	/* Item that currently has the input focus, or
	 * NULL if no such item. Read-only to items. */
	Tk_Item* focusItemPtr;

	/* Non-zero means that the canvas widget has
	 * the input focus. Read-only to items.*/
	int gotFocus;

	/* Non-zero means that an insertion cursor
	 * should be displayed in focusItemPtr.
	 * Read-only to items.*/
	int cursorOn;
}

/*
 * Structures used for Dashing and Outline.
 */
struct Tk_Dash
{
    int number;

    static union pattern_
	{
		ubyte* pt;
		ubyte[(ubyte*).sizeof] array;
    }
	pattern_ pattern;
}

struct Tk_TSOffset
{
    int flags;   /* Flags; see below for possible values */
    int xoffset; /* x offset */
    int yoffset; /* y offset */
}

/*
 * Bit fields in Tk_Offset->flags:
 */
enum TK_OFFSET_INDEX    = 1;
enum TK_OFFSET_RELATIVE = 2;
enum TK_OFFSET_LEFT     = 4;
enum TK_OFFSET_CENTER   = 8;
enum TK_OFFSET_RIGHT    = 16;
enum TK_OFFSET_TOP      = 32;
enum TK_OFFSET_MIDDLE   = 64;
enum TK_OFFSET_BOTTOM   = 128;

struct Tk_Outline
{
    GC gc;                  /* Graphics context. */
    double width;           /* Width of outline. */
    double activeWidth;     /* Width of outline. */
    double disabledWidth;   /* Width of outline. */
    int offset;             /* Dash offset. */
    Tk_Dash dash;           /* Dash pattern. */
    Tk_Dash activeDash;     /* Dash pattern if state is active. */
    Tk_Dash disabledDash;   /* Dash pattern if state is disabled. */
    void* reserved1;        /* Reserved for future expansion. */
    void* reserved2;
    void* reserved3;
    Tk_TSOffset tsoffset;   /* Stipple offset for outline. */
    XColor* color;          /* Outline color. */
    XColor* activeColor;    /* Outline color if state is active. */
    XColor* disabledColor;  /* Outline color if state is disabled. */
    Pixmap stipple;         /* Outline Stipple pattern. */
    Pixmap activeStipple;   /* Outline Stipple pattern if state is active. */
    Pixmap disabledStipple; /* Outline Stipple pattern if state is disabled. */
}

/*
 *--------------------------------------------------------------
 *
 * Procedure prototypes and structures used for managing images:
 *
 *--------------------------------------------------------------
 */
enum USE_OLD_IMAGE = false;

static if (USE_OLD_IMAGE)
{
	alias extern(C) int function(Tcl_Interp* interp, const(char)* name, int argc, const(char)** argv, Tk_ImageType* typePtr, Tk_ImageMaster master, ClientData* masterDataPtr) nothrow Tk_ImageCreateProc;
}
else
{
	alias extern(C) int function(Tcl_Interp* interp, const(char)* name, int objc, const(Tcl_Obj*)[] objv, Tk_ImageType* typePtr, Tk_ImageMaster master, ClientData* masterDataPtr) nothrow Tk_ImageCreateProc;
}
alias extern(C) ClientData function(Tk_Window tkwin, ClientData masterData) nothrow Tk_ImageGetProc;
alias extern(C) void function(ClientData instanceData, Display* display, Drawable drawable, int imageX, int imageY, int width, int height, int drawableX, int drawableY) nothrow Tk_ImageDisplayProc;
alias extern(C) void function(ClientData instanceData, Display* display) nothrow Tk_ImageFreeProc;
alias extern(C) void function(ClientData masterData) nothrow Tk_ImageDeleteProc;
alias extern(C) void function(ClientData clientData, int x, int y, int width, int height, int imageWidth, int imageHeight) nothrow Tk_ImageChangedProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, Tk_Window tkwin, Tk_PostscriptInfo psinfo, int x, int y, int width, int height, int prepass) nothrow Tk_ImagePostscriptProc;

/*
 * The following structure represents a particular type of image (bitmap, xpm
 * image, etc.). It provides information common to all images of that type,
 * such as the type name and a collection of procedures in the image manager
 * that respond to various events. Each image manager is represented by one of
 * these structures.
 */
struct Tk_ImageType
{
	/* Name of image type. */
	const(char)* name;

	/* Procedure to call to create a new image of
	 * this type. */
	Tk_ImageCreateProc createProc;

	/* Procedure to call the first time
	 * Tk_GetImage is called in a new way (new
	 * visual or screen). */
	Tk_ImageGetProc getProc;

	/* Call to draw image, in response to
	 * Tk_RedrawImage calls. */
	Tk_ImageDisplayProc displayProc;

	/* Procedure to call whenever Tk_FreeImage is
	 * called to release an instance of an
	 * image. */
	Tk_ImageFreeProc freeProc;

	/* Procedure to call to delete image. It will
	 * not be called until after freeProc has been
	 * called for each instance of the image. */
	Tk_ImageDeleteProc deleteProc;

	/* Procedure to call to produce postscript
	 * output for the image. */
	Tk_ImagePostscriptProc postscriptProc;

	/* Next in list of all image types currently
	 * known. Filled in by Tk, not by image
	 * manager. */
	Tk_ImageType* nextPtr;

	/* reserved for future expansion */
	void* reserved;
}

/*
 *--------------------------------------------------------------
 *
 * Additional definitions used to manage images of type "photo".
 *
 *--------------------------------------------------------------
 */

/*
 * The following type is used to identify a particular photo image to be
 * manipulated:
 */
alias void* Tk_PhotoHandle;

/*
 * The following structure describes a block of pixels in memory:
 */
struct Tk_PhotoImageBlock
{
	/* Pointer to the first pixel. */
	ubyte* pixelPtr;

	/* Width of block, in pixels. */
	int width;

	/* Height of block, in pixels. */
	int height;

	/* Address difference between corresponding
	 * pixels in successive lines. */
	int pitch;

	/* Address difference between successive
	 * pixels in the same line. */
	int pixelSize;

	/* Address differences between the red, green,
	 * blue and alpha components of the pixel and
	 * the pixel as a whole. */
	int offset[4];
}

/*
 * The following values control how blocks are combined into photo images when
 * the alpha component of a pixel is not 255, a.k.a. the compositing rule.
 */
enum TK_PHOTO_COMPOSITE_OVERLAY = 0;
enum TK_PHOTO_COMPOSITE_SET     = 1;

/*
 * Procedure prototypes and structures used in reading and writing photo
 * images:
 */
static if (USE_OLD_IMAGE)
{
	alias extern(C) int function(Tcl_Channel chan, const(char)* fileName, const(char)* formatString, int* widthPtr, int* heightPtr) nothrow Tk_ImageFileMatchProc;
	alias extern(C) int function(const(char)* string_, const(char)* formatString, int* widthPtr, int* heightPtr) nothrow Tk_ImageStringMatchProc;
	alias extern(C) int function(Tcl_Interp* interp, Tcl_Channel chan, const(char)* fileName, const(char)* formatString, Tk_PhotoHandle imageHandle, int destX, int destY, int width, int height, int srcX, int srcY) nothrow Tk_ImageFileReadProc;
	alias extern(C) int function(Tcl_Interp* interp, const(char)* string, const(char)* formatString, Tk_PhotoHandle imageHandle, int destX, int destY, int width, int height, int srcX, int srcY) nothrow Tk_ImageStringReadProc;
	alias extern(C) int function(Tcl_Interp* interp, const(char)* fileName, const(char)* formatString, Tk_PhotoImageBlock* blockPtr) nothrow Tk_ImageFileWriteProc;
	alias extern(C) int function(Tcl_Interp* interp, Tcl_DString* dataPtr, const(char)* formatString, Tk_PhotoImageBlock* blockPtr) nothrow Tk_ImageStringWriteProc;
}
else
{
	alias extern(C) int function(Tcl_Channel chan, const(char)* fileName, Tcl_Obj* format, int* widthPtr, int* heightPtr, Tcl_Interp* interp) nothrow Tk_ImageFileMatchProc;
	alias extern(C) int function(Tcl_Obj* dataObj, Tcl_Obj* format, int* widthPtr, int* heightPtr, Tcl_Interp* interp) nothrow Tk_ImageStringMatchProc;
	alias extern(C) int function(Tcl_Interp* interp, Tcl_Channel chan, const(char)* fileName, Tcl_Obj* format, Tk_PhotoHandle imageHandle, int destX, int destY, int width, int height, int srcX, int srcY) nothrow Tk_ImageFileReadProc;
	alias extern(C) int function(Tcl_Interp* interp, Tcl_Obj* dataObj, Tcl_Obj* format, Tk_PhotoHandle imageHandle, int destX, int destY, int width, int height, int srcX, int srcY) nothrow Tk_ImageStringReadProc;
	alias extern(C) int function(Tcl_Interp* interp, const(char)* fileName, Tcl_Obj* format, Tk_PhotoImageBlock* blockPtr) nothrow Tk_ImageFileWriteProc;
	alias extern(C) int function(Tcl_Interp* interp, Tcl_Obj* format, Tk_PhotoImageBlock* blockPtr) nothrow Tk_ImageStringWriteProc;
}

/*
 * The following structure represents a particular file format for storing
 * images (e.g., PPM, GIF, JPEG, etc.). It provides information to allow image
 * files of that format to be recognized and read into a photo image.
 */
struct Tk_PhotoImageFormat
{
	/* Name of image file format */
	const(char)* name;

	/* Procedure to call to determine whether an
	 * image file matches this format. */
	Tk_ImageFileMatchProc fileMatchProc;

	/* Procedure to call to determine whether the
	 * data in a string matches this format. */
	Tk_ImageStringMatchProc stringMatchProc;

	/* Procedure to call to read data from an
	 * image file into a photo image. */
	Tk_ImageFileReadProc fileReadProc;

	/* Procedure to call to read data from a
	 * string into a photo image. */
	Tk_ImageStringReadProc stringReadProc;

	/* Procedure to call to write data from a
	 * photo image to a file. */
	Tk_ImageFileWriteProc fileWriteProc;

	/* Procedure to call to obtain a string
	 * representation of the data in a photo
	 * image.*/
	Tk_ImageStringWriteProc stringWriteProc;

	/* Next in list of all photo image formats
	 * currently known. Filled in by Tk, not by
	 * image format handler. */
	Tk_PhotoImageFormat* nextPtr;
}

static if (USE_OLD_IMAGE)
{
	alias Tk_CreateOldImageType        = Tk_CreateImageType;
	alias Tk_CreateOldPhotoImageFormat = Tk_CreatePhotoImageFormat;
}

/*
 *--------------------------------------------------------------
 *
 * Procedure prototypes and structures used for managing styles:
 *
 *--------------------------------------------------------------
 */

/*
 * Style support version tag.
 */
enum TK_STYLE_VERSION_1 = 0x1;
enum TK_STYLE_VERSION   = TK_STYLE_VERSION_1;

/*
 * The following structures and prototypes are used as static templates to
 * declare widget elements.
 */
alias extern(C) void function(ClientData clientData, char* recordPtr, const(Tk_OptionSpec)** optionsPtr, Tk_Window tkwin, int width, int height, int inner, int* widthPtr, int* heightPtr) nothrow Tk_GetElementSizeProc;
alias extern(C) void function(ClientData clientData, char* recordPtr, const(Tk_OptionSpec)** optionsPtr, Tk_Window tkwin, int x, int y, int width, int height, int inner, int* xPtr, int* yPtr, int* widthPtr, int* heightPtr) nothrow Tk_GetElementBoxProc;
alias extern(C) int function(ClientData clientData, char* recordPtr, const(Tk_OptionSpec)** optionsPtr, Tk_Window tkwin) nothrow Tk_GetElementBorderWidthProc;
alias extern(C) void function(ClientData clientData, char* recordPtr, const(Tk_OptionSpec)** optionsPtr, Tk_Window tkwin, Drawable d, int x, int y, int width, int height, int state) nothrow Tk_DrawElementProc;

struct Tk_ElementOptionSpec
{
	/* Name of the required option. */
	const(char)* name;

	/* Accepted option type. TK_OPTION_END means
	 * any. */
	Tk_OptionType type;
}

struct Tk_ElementSpec
{
	/* Version of the style support. */
	int version_;

	/* Name of element. */
	const(char)* name;

	/* List of required options. Last one's name
	 * must be NULL. */
	Tk_ElementOptionSpec* options;

	/* Compute the external (resp. internal) size
	 * of the element from its desired internal
	 * (resp. external) size. */
	Tk_GetElementSizeProc getSize;

	/* Compute the inscribed or bounding boxes
	 * within a given area. */
	Tk_GetElementBoxProc getBox;

	/* Return the element's internal border width.
	 * Mostly useful for widgets. */
	Tk_GetElementBorderWidthProc getBorderWidth;

	/* Draw the element in the given bounding
	 * box. */
	Tk_DrawElementProc draw;
}

/*
 * Element state flags. Can be OR'ed.
 */
enum TK_ELEMENT_STATE_ACTIVE   = (1<<0);
enum TK_ELEMENT_STATE_DISABLED = (1<<1);
enum TK_ELEMENT_STATE_FOCUS    = (1<<2);
enum TK_ELEMENT_STATE_PRESSED  = (1<<3);

/*
 *--------------------------------------------------------------
 *
 * The definitions below provide backward compatibility for functions and
 * types related to event handling that used to be in Tk but have moved to
 * Tcl.
 *
 *--------------------------------------------------------------
 */
alias TK_READABLE           = TCL_READABLE;
alias TK_WRITABLE           = TCL_WRITABLE;
alias TK_EXCEPTION          = TCL_EXCEPTION;
alias TK_DONT_WAIT          = TCL_DONT_WAIT;
alias TK_X_EVENTS           = TCL_WINDOW_EVENTS;
alias TK_WINDOW_EVENTS      = TCL_WINDOW_EVENTS;
alias TK_FILE_EVENTS        = TCL_FILE_EVENTS;
alias TK_TIMER_EVENTS       = TCL_TIMER_EVENTS;
alias TK_IDLE_EVENTS        = TCL_IDLE_EVENTS;
alias TK_ALL_EVENTS         = TCL_ALL_EVENTS;
alias Tk_IdleProc           = Tcl_IdleProc;
alias Tk_FileProc           = Tcl_FileProc;
alias Tk_TimerProc          = Tcl_TimerProc;
alias Tk_TimerToken         = Tcl_TimerToken;
alias Tk_BackgroundError    = Tcl_BackgroundError;
alias Tk_CancelIdleCall     = Tcl_CancelIdleCall;
alias Tk_CreateFileHandler  = Tcl_CreateFileHandler;
alias Tk_CreateTimerHandler = Tcl_CreateTimerHandler;
alias Tk_DeleteFileHandler  = Tcl_DeleteFileHandler;
alias Tk_DeleteTimerHandler = Tcl_DeleteTimerHandler;
alias Tk_DoOneEvent         = Tcl_DoOneEvent;
alias Tk_DoWhenIdle         = Tcl_DoWhenIdle;
alias Tk_Sleep              = Tcl_Sleep;

/* Additional stuff that has moved to Tcl: */
alias Tk_EventuallyFree = Tcl_EventuallyFree;
alias Tk_FreeProc       = Tcl_FreeProc;
alias Tk_Preserve       = Tcl_Preserve;
alias Tk_Release        = Tcl_Release;

/* Removed Tk_Main, use macro instead */
void Tk_Main(int argc, const(char)** argv, Tcl_AppInitProc proc)
{
	Tk_MainEx(argc, argv, proc, Tcl_CreateInterp());
}

extern(C) const(char)* Tk_PkgInitStubsCheck (Tcl_Interp* interp, const(char)* version_, int exact) nothrow;

enum USE_TK_STUBS = false;

static if (USE_TK_STUBS)
{
	const(char)* Tk_InitStubs(Tcl_Interp* interp, const(char)* version_, int exact)
	{
		return Tk_PkgInitStubsCheck(interp, version_, exact);
	}
}
else
{
	extern(C) const(char)* Tk_InitStubs(Tcl_Interp* interp, const(char)* version_, int exact) nothrow;
}

/*
 *--------------------------------------------------------------
 *
 * Additional procedure types defined by Tk.
 *
 *--------------------------------------------------------------
 */
alias extern(C) int function(ClientData clientData, XErrorEvent* errEventPtr) nothrow Tk_ErrorProc;
alias extern(C) void function(ClientData clientData, XEvent* eventPtr) nothrow Tk_EventProc;
alias extern(C) int function(ClientData clientData, XEvent* eventPtr) nothrow Tk_GenericProc;
alias extern(C) int function(Tk_Window tkwin, XEvent* eventPtr) nothrow Tk_ClientMessageProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, ubyte* portion) nothrow Tk_GetSelProc;
alias extern(C) void function(ClientData clientData) nothrow Tk_LostSelProc;
alias extern(C) Tk_RestrictAction function(ClientData clientData, XEvent* eventPtr) nothrow Tk_RestrictProc;
alias extern(C) int function(ClientData clientData, int offset, ubyte* buffer, int maxBytes) nothrow Tk_SelectionProc;

/*
 *--------------------------------------------------------------
 *
 * Platform independant exported procedures and variables.
 *
 *--------------------------------------------------------------
 */
public import tcltk.tkdecls;
