/**
 * D bindings to Tcl/Tk
 *
 * License:
 *     MIT. See LICENSE for full details.
 */
module tcltk.tcl;

import core.stdc.config;
import std.conv;
import std.string;

/*
 * The following defines are used to indicate the various release levels.
 */
enum TCL_ALPHA_RELEASE = 0;
enum TCL_BETA_RELEASE  = 1;
enum TCL_FINAL_RELEASE = 2;

/*
 * When version numbers change here, must also go into the following files and
 * update the version numbers:
 *
 * library/init.tcl	(1 LOC patch)
 * unix/configure.in	(2 LOC Major, 2 LOC minor, 1 LOC patch)
 * win/configure.in	(as above)
 * win/tcl.m4		(not patchlevel)
 * win/makefile.bc	(not patchlevel) 2 LOC
 * README		(sections 0 and 2, with and without separator)
 * macosx/Tcl.pbproj/project.pbxproj (not patchlevel) 1 LOC
 * macosx/Tcl.pbproj/default.pbxuser (not patchlevel) 1 LOC
 * macosx/Tcl.xcode/project.pbxproj (not patchlevel) 2 LOC
 * macosx/Tcl.xcode/default.pbxuser (not patchlevel) 1 LOC
 * macosx/Tcl-Common.xcconfig (not patchlevel) 1 LOC
 * win/README		(not patchlevel) (sections 0 and 2)
 * unix/tcl.spec	(1 LOC patch)
 * tools/tcl.hpj.in	(not patchlevel, for windows installer)
 * tools/tcl.wse.in	(for windows installer)
 * tools/tclSplash.bmp	(not patchlevel)
 */
enum TCL_MAJOR_VERSION  = 8;
enum TCL_MINOR_VERSION  = 6;
enum TCL_RELEASE_LEVEL  = TCL_FINAL_RELEASE;
enum TCL_RELEASE_SERIAL = 1;
enum TCL_VERSION        = "8.6";
enum TCL_PATCH_LEVEL    = "8.6.1";

/*
 * Tcl's public routine Tcl_FSSeek() uses the values SEEK_SET, SEEK_CUR, and
 * SEEK_END, all #define'd by stdio.h .
 *
 * Also, many extensions need stdio.h, and they've grown accustomed to tcl.h
 * providing it for them rather than #include-ing it themselves as they
 * should, so also for their sake, we keep the #include to be consistent with
 * prior Tcl releases.
 */
public import core.stdc.stdio : SEEK_SET, SEEK_CUR, SEEK_END;

/*
 * Miscellaneous declarations.
 */
alias ClientData = void*;

/*
 * Define Tcl_WideInt to be a type that is (at least) 64-bits wide, and define
 * Tcl_WideUInt to be the unsigned variant of that type (assuming that where
 * we have one, we can have the other.)
 *
 * Also defines the following macros:
 * TCL_WIDE_INT_IS_LONG - if wide ints are really longs (i.e. we're on a real
 *	64-bit system.)
 * Tcl_WideAsLong - forgetful converter from wideInt to long.
 * Tcl_LongAsWide - sign-extending converter from long to wideInt.
 * Tcl_WideAsDouble - converter from wideInt to double.
 * Tcl_DoubleAsWide - converter from double to wideInt.
 *
 * The following invariant should hold for any long value 'longVal':
 *	longVal == Tcl_WideAsLong(Tcl_LongAsWide(longVal))
 *
 * Note on converting between Tcl_WideInt and strings. This implementation (in
 * tclObj.c) depends on the function
 * sprintf(...,"%" TCL_LL_MODIFIER "d",...).
 */
version (Windows)
{
	alias _dev_t            = uint;
	alias _ino_t            = ushort;
	alias _mode_t           = ushort;
	alias __int32           = int;
	alias __int64           = long;
	alias __time32_t        = __int32;
	alias __time64_t        = __int64;
	alias TCL_WIDE_INT_TYPE = __int64;
	alias TCL_WIDE_UINT_TYPE = ulong;

	enum TCL_WIDE_INT_IS_LONG = true;

	version (Win64)
	{
		struct __stat64
		{
			_dev_t st_dev;
			_ino_t st_ino;
			_mode_t st_mode;
			short st_nlink;
			short st_uid;
			short st_gid;
			_dev_t st_rdev;
			__int64 st_size;
			__time64_t st_atime;
			__time64_t st_mtime;
			__time64_t st_ctime;
		}
		alias Tcl_StatBuf = __stat64;
	}
	else
	{
		struct _stat32i64
		{
			_dev_t st_dev;
			_ino_t st_ino;
			_mode_t st_mode;
			short st_nlink;
			short st_uid;
			short st_gid;
			_dev_t st_rdev;
			__int64 st_size;
			__time32_t st_atime;
			__time32_t st_mtime;
			__time32_t st_ctime;
		}
		alias Tcl_StatBuf = _stat32i64;
	}
}
else
{
	alias TCL_WIDE_INT_TYPE  = c_long;
	alias TCL_WIDE_UINT_TYPE = c_ulong;

	enum TCL_WIDE_INT_IS_LONG = (TCL_WIDE_INT_TYPE.sizeof > 4);

	import core.sys.posix.sys.stat : stat_t;
	alias Tcl_StatBuf = stat_t;
}

alias Tcl_WideInt  = TCL_WIDE_INT_TYPE;
alias Tcl_WideUInt = TCL_WIDE_UINT_TYPE;

/*
 * Data structures defined opaquely in this module. The definitions below just
 * provide dummy types. A few fields are made visible in Tcl_Interp
 * structures, namely those used for returning a string result from commands.
 * Direct access to the result field is discouraged in Tcl 8.0. The
 * interpreter result is either an object or a string, and the two values are
 * kept consistent unless some C code sets interp->result directly.
 * Programmers should use either the function Tcl_GetObjResult() or
 * Tcl_GetStringResult() to read the interpreter's result. See the SetResult
 * man page for details.
 *
 * Note: any change to the Tcl_Interp definition below must be mirrored in the
 * "real" definition in tclInt.h.
 *
 * Note: Tcl_ObjCmdProc functions do not directly set result and freeProc.
 * Instead, they set a Tcl_Obj member in the "real" structure that can be
 * accessed with Tcl_GetObjResult() and Tcl_SetObjResult().
 */
struct Tcl_Interp
{
	/*
	 * If the last command returned a string result, this points to it.
	 *
	 * Use Tcl_GetStringResult/Tcl_SetResult instead of using this directly.
	 */
	deprecated const(char)* result;
	/*
	 * Zero means the string result is statically allocated. TCL_DYNAMIC
	 * means it was allocated with ckalloc and should be freed with ckfree.
	 * Other values give the address of function to invoke to free the result.
	 * Tcl_Eval must free it before executing next command.
	 *
	 * Use Tcl_GetStringResult/Tcl_SetResult instead of using this directly.
	 */
	deprecated extern(C) void function(char* blockPtr) nothrow freeProc;
	/*
	 * When TCL_ERROR is returned, this gives the line number within the
	 * command where the error occurred (1 if first line).
	 *
	 * Use Tcl_GetErrorLine/Tcl_SetErrorLine instead of using this directly.
	 */
	deprecated int errorLine;
}

struct Tcl_AsyncHandler_;
alias Tcl_AsyncHandler = Tcl_AsyncHandler_*;
struct Tcl_Channel_;
alias Tcl_Channel = Tcl_Channel_*;
struct Tcl_ChannelTypeVersion_;
alias Tcl_ChannelTypeVersion = Tcl_ChannelTypeVersion_*;
struct Tcl_Command_;
alias Tcl_Command = Tcl_Command_*;
struct Tcl_Condition_;
alias Tcl_Condition = Tcl_Condition_*;
struct Tcl_Dict_;
alias Tcl_Dict = Tcl_Dict_*;
struct Tcl_EncodingState_;
alias Tcl_EncodingState = Tcl_EncodingState_*;
struct Tcl_Encoding_;
alias Tcl_Encoding = Tcl_Encoding_*;
struct Tcl_InterpState_;
alias Tcl_InterpState = Tcl_InterpState_*;
struct Tcl_LoadHandle_;
alias Tcl_LoadHandle = Tcl_LoadHandle_*;
struct Tcl_Mutex_;
alias Tcl_Mutex = Tcl_Mutex_*;
struct Tcl_Pid_;
alias Tcl_Pid = Tcl_Pid_*;
struct Tcl_RegExp_;
alias Tcl_RegExp = Tcl_RegExp_*;
struct Tcl_ThreadDataKey_;
alias Tcl_ThreadDataKey = Tcl_ThreadDataKey_*;
struct Tcl_ThreadId_;
alias Tcl_ThreadId = Tcl_ThreadId_*;
struct Tcl_TimerToken_;
alias Tcl_TimerToken = Tcl_TimerToken_*;
struct Tcl_Trace_;
alias Tcl_Trace = Tcl_Trace_*;
struct Tcl_Var_;
alias Tcl_Var = Tcl_Var_*;
struct Tcl_ZLibStream_;
alias Tcl_ZLibStream = Tcl_ZLibStream_*;

/*
 * Definition of the interface to functions implementing threads. A function
 * following this definition is given to each call of 'Tcl_CreateThread' and
 * will be called as the main fuction of the new thread created by that call.
 */
version (Windows)
{
	alias extern(Windows) uint function(ClientData clientData) nothrow Tcl_ThreadCreateProc;
}
else
{
	alias extern(C) void function(ClientData clientData) nothrow Tcl_ThreadCreateProc;
}

/*
 * Threading function return types used for abstracting away platform
 * differences when writing a Tcl_ThreadCreateProc. See the NewThread function
 * in generic/tclThreadTest.c for it's usage.
 */
version (Windows)
{
	alias Tcl_ThreadCreateType    = uint;
	enum TCL_THREAD_CREATE_RETURN = 0;
}
else
{
	alias Tcl_ThreadCreateType = void;
	enum TCL_THREAD_CREATE_RETURN;
}

/*
 * Definition of values for default stacksize and the possible flags to be
 * given to Tcl_CreateThread.
 */
enum TCL_THREAD_STACK_DEFAULT = octal!(0); /* Use default size for stack. */
enum TCL_THREAD_NOFLAGS       = octal!(0); /* Standard flags, default behaviour. */
enum TCL_THREAD_JOINABLE      = octal!(1); /* Mark the thread as joinable. */

/*
 * Flag values passed to Tcl_StringCaseMatch.
 */
enum TCL_MATCH_NOCASE = (1 << 0);

/*
 * Flag values passed to Tcl_GetRegExpFromObj.
 */
enum TCL_REG_BASIC    = octal!(0);    /* BREs (convenience). */
enum TCL_REG_EXTENDED = octal!(1);    /* EREs. */
enum TCL_REG_ADVF     = octal!(2);    /* Advanced features in EREs. */
enum TCL_REG_ADVANCED = octal!(3);    /* AREs (which are also EREs). */
enum TCL_REG_QUOTE    = octal!(4);    /* No special characters, none. */
enum TCL_REG_NOCASE   = octal!(10);   /* Ignore case. */
enum TCL_REG_NOSUB    = octal!(20);   /* Don't care about subexpressions. */
enum TCL_REG_EXPANDED = octal!(40);   /* Expanded format, white space & comments. */
enum TCL_REG_NLSTOP   = octal!(100);  /* \n doesn't match . or [^ ] */
enum TCL_REG_NLANCH   = octal!(200);  /* ^ matches after \n, $ before. */
enum TCL_REG_NEWLINE  = octal!(300);  /* Newlines are line terminators. */
enum TCL_REG_CANMATCH = octal!(1000); /* Report details on partial/limited matches. */

/*
 * Flags values passed to Tcl_RegExpExecObj.
 */
enum TCL_REG_NOTBOL = octal!(1); /* Beginning of string does not match ^.  */
enum TCL_REG_NOTEOL = octal!(2); /* End of string does not match $. */

/*
 * Structures filled in by Tcl_RegExpInfo. Note that all offset values are
 * relative to the start of the match string, not the beginning of the entire
 * string.
 */
struct Tcl_RegExpIndices
{
    c_long start; /* Character offset of first character in match. */
    c_long end;   /* Character offset of first character after the match. */
}

struct Tcl_RegExpInfo
{
    int nsubs;                  /* Number of subexpressions in the compiled expression. */
    Tcl_RegExpIndices* matches; /* Array of nsubs match offset pairs. */
    c_long extendStart;         /* The offset at which a subsequent match might begin. */
    c_long reserved;            /* Reserved for later use. */
}

/*
 * Picky compilers complain if this typdef doesn't appear before the struct's
 * reference in tclDecls.h.
 */
alias Tcl_Stat_    = Tcl_StatBuf;

version(Posix)
{
	alias Tcl_OldStat_ = stat_t;
}

/*
 * When a TCL command returns, the interpreter contains a result from the
 * command. Programmers are strongly encouraged to use one of the functions
 * Tcl_GetObjResult() or Tcl_GetStringResult() to read the interpreter's
 * result. See the SetResult man page for details. Besides this result, the
 * command function returns an integer code, which is one of the following:
 *
 * TCL_OK		Command completed normally; the interpreter's result
 *			contains the command's result.
 * TCL_ERROR		The command couldn't be completed successfully; the
 *			interpreter's result describes what went wrong.
 * TCL_RETURN		The command requests that the current function return;
 *			the interpreter's result contains the function's
 *			return value.
 * TCL_BREAK		The command requests that the innermost loop be
 *			exited; the interpreter's result is meaningless.
 * TCL_CONTINUE		Go on to the next iteration of the current loop; the
 *			interpreter's result is meaningless.
 */
enum TCL_OK          = 0;
enum TCL_ERROR       = 1;
enum TCL_RETURN      = 2;
enum TCL_BREAK       = 3;
enum TCL_CONTINUE    = 4;

enum TCL_RESULT_SIZE = 200;

/*
 * Flags to control what substitutions are performed by Tcl_SubstObj():
 */
enum TCL_SUBST_COMMANDS    = octal!(1);
enum TCL_SUBST_VARIABLES   = octal!(2);
enum TCL_SUBST_BACKSLASHES = octal!(4);
enum TCL_SUBST_ALL         = octal!(7);

/*
 * Argument descriptors for math function callbacks in expressions:
 */
enum Tcl_ValueType
{
    TCL_INT,
	TCL_DOUBLE,
	TCL_EITHER,
	TCL_WIDE_INT,
}

struct Tcl_Value
{
    Tcl_ValueType type;    /* Indicates intValue or doubleValue is valid, or both. */
    c_long intValue;       /* Integer value. */
    double doubleValue;    /* Double-precision floating value. */
    Tcl_WideInt wideValue; /* Wide (min. 64-bit) integer value. */
}

/*
 * Function types defined by Tcl:
 */
alias extern(C) int function(Tcl_Interp* interp) nothrow Tcl_AppInitProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, int code) nothrow Tcl_AsyncProc;
alias extern(C) void function(ClientData clientData, int mask) nothrow Tcl_ChannelProc;
alias extern(C) void function(ClientData data) nothrow Tcl_CloseProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_CmdDeleteProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, int argc, const(char)** argv) nothrow Tcl_CmdProc;
alias extern(C) void function(ClientData clientData, Tcl_Interp* interp, int level, const(char)* command, Tcl_CmdProc proc, ClientData cmdClientData, int argc, const(char)** argv) nothrow Tcl_CmdTraceProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, int level, const(char)* command, Tcl_Command commandInfo, int objc, const(Tcl_Obj*)* objv) nothrow Tcl_CmdObjTraceProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_CmdObjTraceDeleteProc;
alias extern(C) void function(Tcl_Obj* srcPtr, Tcl_Obj* dupPtr) nothrow Tcl_DupInternalRepProc;
alias extern(C) int function(ClientData clientData, const(char)* src, int srcLen, int flags, Tcl_EncodingState* statePtr, const(char)* dst, int dstLen, int* srcReadPtr, int* dstWrotePtr, int* dstCharsPtr) nothrow Tcl_EncodingConvertProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_EncodingFreeProc;
alias extern(C) int function(Tcl_Event* evPtr, int flags) nothrow Tcl_EventProc;
alias extern(C) void function(ClientData clientData, int flags) nothrow Tcl_EventCheckProc;
alias extern(C) int function(Tcl_Event* evPtr, ClientData clientData) nothrow Tcl_EventDeleteProc;
alias extern(C) void function(ClientData clientData, int flags) nothrow Tcl_EventSetupProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_ExitProc;
alias extern(C) void function(ClientData clientData, int mask) nothrow Tcl_FileProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_FileFreeProc;
alias extern(C) void function(Tcl_Obj* objPtr) nothrow Tcl_FreeInternalRepProc;
alias extern(C) void function(const(char)* blockPtr) nothrow Tcl_FreeProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_IdleProc;
alias extern(C) void function(ClientData clientData, Tcl_Interp* interp) nothrow Tcl_InterpDeleteProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, Tcl_Value* args, Tcl_Value* resultPtr) nothrow Tcl_MathProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_NamespaceDeleteProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp* interp, int objc, const(Tcl_Obj*)* objv) nothrow Tcl_ObjCmdProc;
alias extern(C) int function(Tcl_Interp* interp) nothrow Tcl_PackageInitProc;
alias extern(C) int function(Tcl_Interp* interp, int flags) nothrow Tcl_PackageUnloadProc;
alias extern(C) void function(const(char)* format, ...) nothrow Tcl_PanicProc;
alias extern(C) void function(ClientData callbackData, Tcl_Channel chan, const(char)* address, int port) nothrow Tcl_TcpAcceptProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_TimerProc;
alias extern(C) int function(Tcl_Interp* interp, Tcl_Obj* objPtr) nothrow Tcl_SetFromAnyProc;
alias extern(C) void function(Tcl_Obj* objPtr) nothrow Tcl_UpdateStringProc;
alias extern(C) const(char)* function(ClientData clientData, Tcl_Interp* interp, const(char)* part1, const(char)* part2, int flags) nothrow Tcl_VarTraceProc;
alias extern(C) void function(ClientData clientData, Tcl_Interp* interp, const(char)* oldName, const(char)* newName, int flags) nothrow Tcl_CommandTraceProc;
alias extern(C) void function(int fd, int mask, Tcl_FileProc proc, ClientData clientData) nothrow Tcl_CreateFileHandlerProc;
alias extern(C) void function(int fd) nothrow Tcl_DeleteFileHandlerProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_AlertNotifierProc;
alias extern(C) void function(int mode) nothrow Tcl_ServiceModeHookProc;
alias extern(C) ClientData function() nothrow Tcl_InitNotifierProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_FinalizeNotifierProc;
alias extern(C) void function() nothrow Tcl_MainLoopProc;

/*
 * The following structure represents a type of object, which is a particular
 * internal representation for an object plus a set of functions that provide
 * standard operations on objects of that type.
 */
struct Tcl_ObjType
{
	/* Name of the type, e.g. "int". */
    char *name;

	/* Called to free any storage for the type's
	 * internal rep. NULL if the internal rep does
	 * not need freeing. */
    Tcl_FreeInternalRepProc freeIntRepProc;

	/* Called to create a new object as a copy of
	 * an existing object. */
    Tcl_DupInternalRepProc dupIntRepProc;

	/* Called to update the string rep from the
	 * type's internal representation. */
    Tcl_UpdateStringProc updateStringProc;

	/* Called to convert the object's internal rep
	 * to this type. Frees the internal rep of the
	 * old type. Returns TCL_ERROR on failure. */
    Tcl_SetFromAnyProc setFromAnyProc;
}

/*
 * One of the following structures exists for each object in the Tcl system.
 * An object stores a value as either a string, some internal representation,
 * or both.
 */
struct Tcl_Obj
{
	/* When 0 the object will be freed. */
    int refCount;

	/* This points to the first byte of the
	 * object's string representation. The array
	 * must be followed by a null byte (i.e., at
	 * offset length) but may also contain
	 * embedded null characters. The array's
	 * storage is allocated by ckalloc. NULL means
	 * the string rep is invalid and must be
	 * regenerated from the internal rep.  Clients
	 * should use Tcl_GetStringFromObj or
	 * Tcl_GetString to get a pointer to the byte
	 * array as a readonly value. */
    const(char)* bytes;

	/* The number of bytes at *bytes, not
	 * including the terminating null. */
    int length;

	/* Denotes the object's type. Always
	 * corresponds to the type of the object's
	 * internal rep. NULL indicates the object has
	 * no internal rep (has no type). */
    Tcl_ObjType* typePtr;

    static union internalRep_        /* The internal representation: */
	{
		c_long longValue;            /*   - an long integer value. */
		double doubleValue;          /*   - a double-precision floating value. */
		void* otherValuePtr;         /*   - another, type-specific value. */
		Tcl_WideInt wideValue;       /*   - a long long value. */

		static struct twoPtrValue_   /*   - internal rep as two pointers. */
		{
			void* ptr1;
			void* ptr2;
		}
		twoPtrValue_ twoPtrValue;

		/*- internal rep as a pointer and a long,
		* the main use of which is a bignum's
		* tightly packed fields, where the alloc,
		* used and signum flags are packed into a
		* single word with everything else hung
		* off the pointer.
		*/
		static struct ptrAndLongRep_
		{
			void* ptr;
			c_ulong value;
		}
		ptrAndLongRep_ ptrAndLongRep;
    }
	internalRep_ internalRep;
}

/*
 * The following structure contains the state needed by Tcl_SaveResult. No-one
 * outside of Tcl should access any of these fields. This structure is
 * typically allocated on the stack.
 */
struct Tcl_SavedResult
{
	const(char)* result;
	Tcl_FreeProc freeProc;
	Tcl_Obj* objResultPtr;
	const(char)* appendResult;
	int appendAvl;
	int appendUsed;
	char[TCL_RESULT_SIZE + 1] resultSpace;
}

/*
 * The following definitions support Tcl's namespace facility. Note: the first
 * five fields must match exactly the fields in a Namespace structure (see
 * tclInt.h).
 */
struct Tcl_Namespace
{
	/* The namespace's name within its parent
	 * namespace. This contains no ::'s. The name
	 * of the global namespace is "" although "::"
	 * is an synonym. */
    const(char)* name;

	/* The namespace's fully qualified name. This
	 * starts with ::. */
    const(char)* fullName;

	/* Arbitrary value associated with this
	 * namespace. */
    ClientData clientData;

	/* Function invoked when deleting the
	 * namespace to, e.g., free clientData. */
    Tcl_NamespaceDeleteProc deleteProc;

	/* Points to the namespace that contains this
	 * one. NULL if this is the global
	 * namespace. */
    Tcl_Namespace* parentPtr;
}

/*
 * The following structure represents a call frame, or activation record. A
 * call frame defines a naming context for a procedure call: its local scope
 * (for local variables) and its namespace scope (used for non-local
 * variables; often the global :: namespace). A call frame can also define the
 * naming context for a namespace eval or namespace inscope command: the
 * namespace in which the command's code should execute. The Tcl_CallFrame
 * structures exist only while procedures or namespace eval/inscope's are
 * being executed, and provide a Tcl call stack.
 *
 * A call frame is initialized and pushed using Tcl_PushCallFrame and popped
 * using Tcl_PopCallFrame. Storage for a Tcl_CallFrame must be provided by the
 * Tcl_PushCallFrame caller, and callers typically allocate them on the C call
 * stack for efficiency. For this reason, Tcl_CallFrame is defined as a
 * structure and not as an opaque token. However, most Tcl_CallFrame fields
 * are hidden since applications should not access them directly; others are
 * declared as "dummyX".
 *
 * WARNING!! The structure definition must be kept consistent with the
 * CallFrame structure in tclInt.h. If you change one, change the other.
 */
struct Tcl_CallFrame
{
	Tcl_Namespace* nsPtr;
	int dummy1;
	int dummy2;
	void* dummy3;
	void* dummy4;
	void* dummy5;
	int dummy6;
	void* dummy7;
	void* dummy8;
	int dummy9;
	void* dummy10;
	void* dummy11;
	void* dummy12;
	void* dummy13;
}

/*
 * Information about commands that is returned by Tcl_GetCommandInfo and
 * passed to Tcl_SetCommandInfo. objProc is an objc/objv object-based command
 * function while proc is a traditional Tcl argc/argv string-based function.
 * Tcl_CreateObjCommand and Tcl_CreateCommand ensure that both objProc and
 * proc are non-NULL and can be called to execute the command. However, it may
 * be faster to call one instead of the other. The member isNativeObjectProc
 * is set to 1 if an object-based function was registered by
 * Tcl_CreateObjCommand, and to 0 if a string-based function was registered by
 * Tcl_CreateCommand. The other function is typically set to a compatibility
 * wrapper that does string-to-object or object-to-string argument conversions
 * then calls the other function.
 */
struct Tcl_CmdInfo
{
	/* 1 if objProc was registered by a call to
	 * Tcl_CreateObjCommand; 0 otherwise.
	 * Tcl_SetCmdInfo does not modify this
	 * field. */
	int isNativeObjectProc;

	/* Command's object-based function. */
	Tcl_ObjCmdProc objProc;

	/* ClientData for object proc. */
	ClientData objClientData;

	/* Command's string-based function. */
	Tcl_CmdProc proc;

	/* ClientData for string proc. */
	ClientData clientData;

	/* Function to call when command is
	 * deleted. */
	Tcl_CmdDeleteProc deleteProc;

	/* Value to pass to deleteProc (usually the
	 * same as clientData). */
	ClientData deleteData;

	/* Points to the namespace that contains this
	 * command. Note that Tcl_SetCmdInfo will not
	 * change a command's namespace; use
	 * TclRenameCommand or Tcl_Eval (of 'rename')
	 * to do that. */
	Tcl_Namespace* namespacePtr;
}

/*
 * The structure defined below is used to hold dynamic strings. The only
 * fields that clients should use are string and length, accessible via the
 * macros Tcl_DStringValue and Tcl_DStringLength.
 */
enum TCL_DSTRING_STATIC_SIZE = 200;

struct Tcl_DString
{
	/* Points to beginning of string: either staticSpace below or a malloced array. */
	const(char)* string_;

	/* Number of non-NULL characters in the string. */
	int length;

	/* Total number of bytes available for the string and its terminating NULL char. */
	int spaceAvl;

	/* Space to use in common case where string is small. */
	char[TCL_DSTRING_STATIC_SIZE] staticSpace;
}

extern(C) int Tcl_DStringLength(Tcl_DString* dsPtr) nothrow
{
	return (*dsPtr).length;
}

extern(C) const(char)* Tcl_DStringValue(Tcl_DString* dsPtr) nothrow
{
	return (*dsPtr).string_;
}

/*
 * Definitions for the maximum number of digits of precision that may be
 * specified in the "tcl_precision" variable, and the number of bytes of
 * buffer space required by Tcl_PrintDouble.
 */
enum TCL_MAX_PREC     = 17;
enum TCL_DOUBLE_SPACE = (TCL_MAX_PREC + 10);

/*
 * Definition for a number of bytes of buffer space sufficient to hold the
 * string representation of an integer in base 10 (assuming the existence of
 * 64-bit integers).
 */
enum TCL_INTEGER_SPACE = 24;

/*
 * Flag values passed to Tcl_ConvertElement.
 * TCL_DONT_USE_BRACES forces it not to enclose the element in braces, but to
 *	use backslash quoting instead.
 * TCL_DONT_QUOTE_HASH disables the default quoting of the '#' character. It
 *	is safe to leave the hash unquoted when the element is not the first
 *	element of a list, and this flag can be used by the caller to indicate
 *	that condition.
 */
enum TCL_DONT_USE_BRACES = 1;
enum TCL_DONT_QUOTE_HASH = 8;

/*
 * Flag that may be passed to Tcl_GetIndexFromObj to force it to disallow
 * abbreviated strings.
 */
enum TCL_EXACT = 1;

/*
 * Flag values passed to Tcl_RecordAndEval, Tcl_EvalObj, Tcl_EvalObjv.
 * WARNING: these bit choices must not conflict with the bit choices for
 * evalFlag bits in tclInt.h!
 *
 * Meanings:
 *	TCL_NO_EVAL:		Just record this command
 *	TCL_EVAL_GLOBAL:	Execute script in global namespace
 *	TCL_EVAL_DIRECT:	Do not compile this script
 *	TCL_EVAL_INVOKE:	Magical Tcl_EvalObjv mode for aliases/ensembles
 *				o Run in iPtr->lookupNsPtr or global namespace
 *				o Cut out of error traces
 *				o Don't reset the flags controlling ensemble
 *				  error message rewriting.
 */
enum TCL_NO_EVAL       = 0x010000;
enum TCL_EVAL_GLOBAL   = 0x020000;
enum TCL_EVAL_DIRECT   = 0x040000;
enum TCL_EVAL_INVOKE   = 0x080000;
enum TCL_CANCEL_UNWIND = 0x100000;
enum TCL_EVAL_NOERR    = 0x200000;

/*
 * Special freeProc values that may be passed to Tcl_SetResult (see the man
 * page for details):
 */
enum TCL_VOLATILE = (cast(Tcl_FreeProc)1);
enum TCL_STATIC   = (cast(Tcl_FreeProc)0);
enum TCL_DYNAMIC  = (cast(Tcl_FreeProc)3);

/*
 * Flag values passed to variable-related functions.
 * WARNING: these bit choices must not conflict with the bit choice for
 * TCL_CANCEL_UNWIND, above.
 */
enum TCL_GLOBAL_ONLY          = 1;
enum TCL_NAMESPACE_ONLY       = 2;
enum TCL_APPEND_VALUE         = 4;
enum TCL_LIST_ELEMENT         = 8;
enum TCL_TRACE_READS          = 0x10;
enum TCL_TRACE_WRITES         = 0x20;
enum TCL_TRACE_UNSETS         = 0x40;
enum TCL_TRACE_DESTROYED      = 0x80;
enum TCL_INTERP_DESTROYED     = 0x100;
enum TCL_LEAVE_ERR_MSG        = 0x200;
enum TCL_TRACE_ARRAY          = 0x800;
/* Required to support old variable/vdelete/vinfo traces. */
enum TCL_TRACE_OLD_STYLE      = 0x1000;
/* Indicate the semantics of the result of a trace. */
enum TCL_TRACE_RESULT_DYNAMIC = 0x8000;
enum TCL_TRACE_RESULT_OBJECT  = 0x10000;

/*
 * Flag value to say whether to allow
 * unambiguous prefixes of commands or to
 * require exact matches for command names.
 */
enum TCL_ENSEMBLE_PREFIX = 0x02;

/*
 * Flag values passed to command-related functions.
 */
enum TCL_TRACE_RENAME             = 0x2000;
enum TCL_TRACE_DELETE             = 0x4000;
enum TCL_ALLOW_INLINE_COMPILATION = 0x20000;

/*
 * The TCL_PARSE_PART1 flag is deprecated and has no effect. The part1 is now
 * always parsed whenever the part2 is NULL. (This is to avoid a common error
 * when converting code to use the new object based APIs and forgetting to
 * give the flag)
 */
enum TCL_PARSE_PART1 = 0x400;

/*
 * Types for linked variables:
 */
enum TCL_LINK_INT       = 1;
enum TCL_LINK_DOUBLE    = 2;
enum TCL_LINK_BOOLEAN   = 3;
enum TCL_LINK_STRING    = 4;
enum TCL_LINK_WIDE_INT  = 5;
enum TCL_LINK_CHAR      = 6;
enum TCL_LINK_UCHAR     = 7;
enum TCL_LINK_SHORT     = 8;
enum TCL_LINK_USHORT    = 9;
enum TCL_LINK_UINT      = 10;
enum TCL_LINK_LONG      = 11;
enum TCL_LINK_ULONG     = 12;
enum TCL_LINK_FLOAT     = 13;
enum TCL_LINK_WIDE_UINT = 14;
enum TCL_LINK_READ_ONLY = 0x80;

alias extern(C) uint function(Tcl_HashTable* tablePtr, void* keyPtr) nothrow Tcl_HashKeyProc;
alias extern(C) int function(void* keyPtr, Tcl_HashEntry* hPtr) nothrow Tcl_CompareHashKeysProc;
alias extern(C) Tcl_HashEntry* function(Tcl_HashTable* tablePtr, void* keyPtr) nothrow Tcl_AllocHashEntryProc;
alias extern(C) void function(Tcl_HashEntry* hPtr) nothrow Tcl_FreeHashEntryProc;

/*
 * This flag controls whether the hash table stores the hash of a key, or
 * recalculates it. There should be no reason for turning this flag off as it
 * is completely binary and source compatible unless you directly access the
 * bucketPtr member of the Tcl_HashTableEntry structure. This member has been
 * removed and the space used to store the hash value.
 */
enum TCL_HASH_KEY_STORE_HASH = 1;

/*
 * Structure definition for an entry in a hash table. No-one outside Tcl
 * should access any of these fields directly; use the macros defined below.
 */
struct Tcl_HashEntry
{
    Tcl_HashEntry* nextPtr;  /* Pointer to next entry in this hash bucket, or NULL for end of chain. */
    Tcl_HashTable* tablePtr; /* Pointer to table containing entry. */

	static if (TCL_HASH_KEY_STORE_HASH)
	{
		/* Hash value, stored as pointer to ensure
		 * that the offsets of the fields in this
		 * structure are not changed. */
    	void* hash;
	}
	else
	{
		/* Pointer to bucket that points to first
		 * entry in this entry's chain: used for
		 * deleting the entry. */
		Tcl_HashEntry** bucketPtr;
	}

    ClientData clientData;	/* Application stores something here with Tcl_SetHashValue. */

    static union key_
	{
		/* Key has one of these forms: */

		/* One-word value for key. */
		const(char)* oneWordValue;

		/* Tcl_Obj * key value. */
		Tcl_Obj* objPtr;

		/* Multiple integer words for key. The actual
		 * size will be as large as necessary for this
		 * table's keys. */
		int[1] words;

		/* String for key. The actual size will be as
		 * large as needed to hold the key. */
		char[1] string_;
    }			

	/* MUST BE LAST FIELD IN RECORD!! */
	key_ key;
}

/*
 * Flags used in Tcl_HashKeyType.
 *
 * TCL_HASH_KEY_RANDOMIZE_HASH -
 *				There are some things, pointers for example
 *				which don't hash well because they do not use
 *				the lower bits. If this flag is set then the
 *				hash table will attempt to rectify this by
 *				randomising the bits and then using the upper
 *				N bits as the index into the table.
 * TCL_HASH_KEY_SYSTEM_HASH -	If this flag is set then all memory internally
 *                              allocated for the hash table that is not for an
 *                              entry will use the system heap.
 */
enum TCL_HASH_KEY_RANDOMIZE_HASH = 0x1;
enum TCL_HASH_KEY_SYSTEM_HASH    = 0x2;

/*
 * Structure definition for the methods associated with a hash table key type.
 */
enum TCL_HASH_KEY_TYPE_VERSION = 1;

struct Tcl_HashKeyType
{
	/* Version of the table. If this structure is
	 * extended in future then the version can be
	 * used to distinguish between different
	 * structures. */
	int version_;

	/* Flags, see above for details. */
	int flags;

	/* Calculates a hash value for the key. If
	 * this is NULL then the pointer itself is
	 * used as a hash value. */
	Tcl_HashKeyProc hashKeyProc;

	/* Compares two keys and returns zero if they
	 * do not match, and non-zero if they do. If
	 * this is NULL then the pointers are
	 * compared. */
	Tcl_CompareHashKeysProc compareKeysProc;

	/* Called to allocate memory for a new entry,
	 * i.e. if the key is a string then this could
	 * allocate a single block which contains
	 * enough space for both the entry and the
	 * string. Only the key field of the allocated
	 * Tcl_HashEntry structure needs to be filled
	 * in. If something else needs to be done to
	 * the key, i.e. incrementing a reference
	 * count then that should be done by this
	 * function. If this is NULL then Tcl_Alloc is
	 * used to allocate enough space for a
	 * Tcl_HashEntry and the key pointer is
	 * assigned to key.oneWordValue. */
	Tcl_AllocHashEntryProc allocEntryProc;

	/* Called to free memory associated with an
	 * entry. If something else needs to be done
	 * to the key, i.e. decrementing a reference
	 * count then that should be done by this
	 * function. If this is NULL then Tcl_Free is
	 * used to free the Tcl_HashEntry. */
	Tcl_FreeHashEntryProc freeEntryProc;
}

/*
 * Structure definition for a hash table.  Must be in tcl.h so clients can
 * allocate space for these structures, but clients should never access any
 * fields in this structure.
 */
enum TCL_SMALL_HASH_TABLE = 4;

struct Tcl_HashTable
{
	/* Pointer to bucket array. Each element
	 * points to first entry in bucket's hash
	 * chain, or NULL. */
	Tcl_HashEntry** buckets;

	/* Bucket array used for small tables (to
	 * avoid mallocs and frees). */
	Tcl_HashEntry[TCL_SMALL_HASH_TABLE]* staticBuckets;

	/* Total number of buckets allocated at
	 * **bucketPtr. */
	int numBuckets;

	/* Total number of entries present in
	 * table. */
	int numEntries;

	/* Enlarge table when numEntries gets to be
	 * this large. */
	int rebuildSize;

	/* Shift count used in hashing function.
	 * Designed to use high-order bits of
	 * randomized keys. */
	int downShift;

	/* Mask value used in hashing function. */
	int mask;

	/* Type of keys used in this table. It's
	 * either TCL_CUSTOM_KEYS, TCL_STRING_KEYS,
	 * TCL_ONE_WORD_KEYS, or an integer giving the
	 * number of ints that is the size of the
	 * key. */
	int keyType;

	extern(C) Tcl_HashEntry* function(Tcl_HashTable* tablePtr, const(char)* key) nothrow findProc;
	extern(C) Tcl_HashEntry* function(Tcl_HashTable* tablePtr, const(char)* key, int* newPtr) nothrow createProc;

	/* Type of the keys used in the Tcl_HashTable. */
	Tcl_HashKeyType *typePtr;
};

/*
 * Structure definition for information used to keep track of searches through
 * hash tables:
 */
struct Tcl_HashSearch
{
	Tcl_HashTable* tablePtr;     /* Table being searched. */
	int nextIndex;               /* Index of next bucket to be enumerated after present one. */
	Tcl_HashEntry* nextEntryPtr; /* Next entry to be enumerated in the current bucket. */
}

/*
 * Acceptable key types for hash tables:
 *
 * TCL_STRING_KEYS:		The keys are strings, they are copied into the
 *				entry.
 * TCL_ONE_WORD_KEYS:		The keys are pointers, the pointer is stored
 *				in the entry.
 * TCL_CUSTOM_TYPE_KEYS:	The keys are arbitrary types which are copied
 *				into the entry.
 * TCL_CUSTOM_PTR_KEYS:		The keys are pointers to arbitrary types, the
 *				pointer is stored in the entry.
 *
 * While maintaining binary compatability the above have to be distinct values
 * as they are used to differentiate between old versions of the hash table
 * which don't have a typePtr and new ones which do. Once binary compatability
 * is discarded in favour of making more wide spread changes TCL_STRING_KEYS
 * can be the same as TCL_CUSTOM_TYPE_KEYS, and TCL_ONE_WORD_KEYS can be the
 * same as TCL_CUSTOM_PTR_KEYS because they simply determine how the key is
 * accessed from the entry and not the behaviour.
 */
enum TCL_STRING_KEYS      = (0);
enum TCL_ONE_WORD_KEYS    = (1);
enum TCL_CUSTOM_TYPE_KEYS = (-2);
enum TCL_CUSTOM_PTR_KEYS  = (-1);

/*
 * Structure definition for information used to keep track of searches through
 * dictionaries. These fields should not be accessed by code outside
 * tclDictObj.c
 */
struct Tcl_DictSearch
{
	void* next;             /* Search position for underlying hash table. */
	int epoch;              /* Epoch marker for dictionary being searched, or -1 if search has terminated. */
	Tcl_Dict dictionaryPtr; /* Reference to dictionary being searched. */
}

/*
 * Flag values to pass to Tcl_DoOneEvent to disable searches for some kinds of
 * events:
 */
enum TCL_DONT_WAIT     = (1<<1);
enum TCL_WINDOW_EVENTS = (1<<2);
enum TCL_FILE_EVENTS   = (1<<3);
enum TCL_TIMER_EVENTS  = (1<<4);
enum TCL_IDLE_EVENTS   = (1<<5);	/* WAS 0x10 ???? */
enum TCL_ALL_EVENTS    = (~TCL_DONT_WAIT);

/*
 * The following structure defines a generic event for the Tcl event system.
 * These are the things that are queued in calls to Tcl_QueueEvent and
 * serviced later by Tcl_DoOneEvent. There can be many different kinds of
 * events with different fields, corresponding to window events, timer events,
 * etc. The structure for a particular event consists of a Tcl_Event header
 * followed by additional information specific to that event.
 */
struct Tcl_Event
{
	Tcl_EventProc proc; /* Function to call to service this event. */
	Tcl_Event* nextPtr;  /* Next in list of pending events, or NULL. */
}

/*
 * Positions to pass to Tcl_QueueEvent:
 */
enum Tcl_QueuePosition
{
	TCL_QUEUE_TAIL,
	TCL_QUEUE_HEAD,
	TCL_QUEUE_MARK,
}

/*
 * Values to pass to Tcl_SetServiceMode to specify the behavior of notifier
 * event routines.
 */
enum TCL_SERVICE_NONE = 0;
enum TCL_SERVICE_ALL  = 1;

/*
 * The following structure keeps is used to hold a time value, either as an
 * absolute time (the number of seconds from the epoch) or as an elapsed time.
 * On Unix systems the epoch is Midnight Jan 1, 1970 GMT.
 */
struct Tcl_Time
{
    c_long sec;  /* Seconds. */
    c_long usec; /* Microseconds. */
}

alias extern(C) void function(const(Tcl_Time)* timePtr) nothrow Tcl_SetTimerProc;
alias extern(C) int function(const(Tcl_Time)* timePtr) nothrow Tcl_WaitForEventProc;

/*
 * TIP #233 (Virtualized Time)
 */
alias extern(C) void function(Tcl_Time* timebuf, ClientData clientData) nothrow Tcl_GetTimeProc;
alias extern(C) void function(Tcl_Time* timebuf, ClientData clientData) nothrow Tcl_ScaleTimeProc;

/*
 * Bits to pass to Tcl_CreateFileHandler and Tcl_CreateChannelHandler to
 * indicate what sorts of events are of interest:
 */
enum TCL_READABLE  = (1<<1);
enum TCL_WRITABLE  = (1<<2);
enum TCL_EXCEPTION = (1<<3);

/*
 * Flag values to pass to Tcl_OpenCommandChannel to indicate the disposition
 * of the stdio handles. TCL_STDIN, TCL_STDOUT, TCL_STDERR, are also used in
 * Tcl_GetStdChannel.
 */
enum TCL_STDIN        = (1<<1);
enum TCL_STDOUT       = (1<<2);
enum TCL_STDERR       = (1<<3);
enum TCL_ENFORCE_MODE = (1<<4);

/*
 * Bits passed to Tcl_DriverClose2Proc to indicate which side of a channel
 * should be closed.
 */
enum TCL_CLOSE_READ  = (1<<1);
enum TCL_CLOSE_WRITE = (1<<2);

/*
 * Value to use as the closeProc for a channel that supports the close2Proc
 * interface.
 */
enum TCL_CLOSE2PROC = cast(Tcl_DriverCloseProc)1;

/*
 * Channel version tag. This was introduced in 8.3.2/8.4.
 */
enum TCL_CHANNEL_VERSION_1 = cast(Tcl_ChannelTypeVersion)0x1;
enum TCL_CHANNEL_VERSION_2 = cast(Tcl_ChannelTypeVersion)0x2;
enum TCL_CHANNEL_VERSION_3 = cast(Tcl_ChannelTypeVersion)0x3;
enum TCL_CHANNEL_VERSION_4 = cast(Tcl_ChannelTypeVersion)0x4;
enum TCL_CHANNEL_VERSION_5 = cast(Tcl_ChannelTypeVersion)0x5;

/*
 * TIP #218: Channel Actions, Ids for Tcl_DriverThreadActionProc.
 */
enum TCL_CHANNEL_THREAD_INSERT = (0);
enum TCL_CHANNEL_THREAD_REMOVE = (1);

/*
 * Typedefs for the various operations in a channel type:
 */
alias extern(C) int function(ClientData instanceData, int mode) nothrow Tcl_DriverBlockModeProc;
alias extern(C) int function(ClientData instanceData, Tcl_Interp* interp) nothrow Tcl_DriverCloseProc;
alias extern(C) int function(ClientData instanceData, Tcl_Interp* interp, int flags) nothrow Tcl_DriverClose2Proc;
alias extern(C) int function(ClientData instanceData, const(char)* buf, int toRead, int* errorCodePtr) nothrow Tcl_DriverInputProc;
alias extern(C) int function(ClientData instanceData, const(char)* buf, int toWrite, int* errorCodePtr) nothrow Tcl_DriverOutputProc;
alias extern(C) int function(ClientData instanceData, long offset, int mode, int* errorCodePtr) nothrow Tcl_DriverSeekProc;
alias extern(C) int function(ClientData instanceData, Tcl_Interp* interp, const(char)* optionName, const(char)* value) nothrow Tcl_DriverSetOptionProc;
alias extern(C) int function(ClientData instanceData, Tcl_Interp* interp, const(char)* optionName, Tcl_DString* dsPtr) nothrow Tcl_DriverGetOptionProc;
alias extern(C) void function(ClientData instanceData, int mask) nothrow Tcl_DriverWatchProc;
alias extern(C) int function(ClientData instanceData, int direction, ClientData* handlePtr) nothrow Tcl_DriverGetHandleProc;
alias extern(C) int function(ClientData instanceData) nothrow Tcl_DriverFlushProc;
alias extern(C) int function(ClientData instanceData, int interestMask) nothrow Tcl_DriverHandlerProc;
alias extern(C) Tcl_WideInt function(ClientData instanceData, Tcl_WideInt offset, int mode, int* errorCodePtr) nothrow Tcl_DriverWideSeekProc;

/*
 * TIP #218, Channel Thread Actions
 */
alias extern(C) void function(ClientData instanceData, int action) nothrow Tcl_DriverThreadActionProc;

/*
 * TIP #208, File Truncation (etc.)
 */
alias extern(C) int function(ClientData instanceData, Tcl_WideInt length) nothrow Tcl_DriverTruncateProc;

/*
 * struct Tcl_ChannelType:
 *
 * One such structure exists for each type (kind) of channel. It collects
 * together in one place all the functions that are part of the specific
 * channel type.
 *
 * It is recommend that the Tcl_Channel* functions are used to access elements
 * of this structure, instead of direct accessing.
 */
struct Tcl_ChannelType
{
	/* The name of the channel type in Tcl
	 * commands. This storage is owned by channel
	 * type. */
	const(char)* typeName;

	/* Version of the channel type. */
	Tcl_ChannelTypeVersion version_;

	/* Function to call to close the channel, or
	 * TCL_CLOSE2PROC if the close2Proc should be
	 * used instead. */
	Tcl_DriverCloseProc closeProc;

	/* Function to call for input on channel. */
	Tcl_DriverInputProc inputProc;

	/* Function to call for output on channel. */
	Tcl_DriverOutputProc outputProc;

	/* Function to call to seek on the channel.
	 * May be NULL. */
	Tcl_DriverSeekProc seekProc;

	/* Set an option on a channel. */
	Tcl_DriverSetOptionProc setOptionProc;

	/* Get an option from a channel. */
	Tcl_DriverGetOptionProc getOptionProc;

	/* Set up the notifier to watch for events on
	 * this channel. */
	Tcl_DriverWatchProc watchProc;

	/* Get an OS handle from the channel or NULL
	 * if not supported. */
	Tcl_DriverGetHandleProc getHandleProc;

	/* Function to call to close the channel if
	 * the device supports closing the read &
	 * write sides independently. */
	Tcl_DriverClose2Proc close2Proc;

	/* Set blocking mode for the raw channel. May
	 * be NULL. */
	Tcl_DriverBlockModeProc blockModeProc;

	/*
	 * Only valid in TCL_CHANNEL_VERSION_2 channels or later.
	 */

	/* Function to call to flush a channel. May be
	 * NULL. */
	Tcl_DriverFlushProc flushProc;

	/* Function to call to handle a channel event.
	 * This will be passed up the stacked channel
	 * chain. */
	Tcl_DriverHandlerProc handlerProc;

	/*
	 * Only valid in TCL_CHANNEL_VERSION_3 channels or later.
	 */

	/* Function to call to seek on the channel
	 * which can handle 64-bit offsets. May be
	 * NULL, and must be NULL if seekProc is
	 * NULL. */
	Tcl_DriverWideSeekProc wideSeekProc;

	/*
	 * Only valid in TCL_CHANNEL_VERSION_4 channels or later.
	 * TIP #218, Channel Thread Actions.
	 */

	/* Function to call to notify the driver of
	 * thread specific activity for a channel. May
	 * be NULL. */
	Tcl_DriverThreadActionProc threadActionProc;

	/*
	 * Only valid in TCL_CHANNEL_VERSION_5 channels or later.
	 * TIP #208, File Truncation.
	 */

	/* Function to call to truncate the underlying
	 * file to a particular length. May be NULL if
	 * the channel does not support truncation. */
	Tcl_DriverTruncateProc truncateProc;
}

/*
 * The following flags determine whether the blockModeProc above should set
 * the channel into blocking or nonblocking mode. They are passed as arguments
 * to the blockModeProc function in the above structure.
 */
enum TCL_MODE_BLOCKING = 0;    /* Put channel into blocking mode. */
enum TCL_MODE_NONBLOCKING = 1; /* Put channel into nonblocking mode. */

/*
 * Enum for different types of file paths.
 */
enum Tcl_PathType
{
    TCL_PATH_ABSOLUTE,
    TCL_PATH_RELATIVE,
    TCL_PATH_VOLUME_RELATIVE,
}

/*
 * The following structure is used to pass glob type data amongst the various
 * glob routines and Tcl_FSMatchInDirectory.
 */
struct Tcl_GlobTypeData
{
    int type;            /* Corresponds to bcdpfls as in 'find -t'. */
    int perm;            /* Corresponds to file permissions. */
    Tcl_Obj* macType;    /* Acceptable Mac type. */
    Tcl_Obj* macCreator; /* Acceptable Mac creator. */
}

/*
 * Type and permission definitions for glob command.
 */
enum TCL_GLOB_TYPE_BLOCK  = (1<<0);
enum TCL_GLOB_TYPE_CHAR   = (1<<1);
enum TCL_GLOB_TYPE_DIR    = (1<<2);
enum TCL_GLOB_TYPE_PIPE   = (1<<3);
enum TCL_GLOB_TYPE_FILE   = (1<<4);
enum TCL_GLOB_TYPE_LINK   = (1<<5);
enum TCL_GLOB_TYPE_SOCK   = (1<<6);
enum TCL_GLOB_TYPE_MOUNT  = (1<<7);

enum TCL_GLOB_PERM_RONLY  = (1<<0);
enum TCL_GLOB_PERM_HIDDEN = (1<<1);
enum TCL_GLOB_PERM_R      = (1<<2);
enum TCL_GLOB_PERM_W      = (1<<3);
enum TCL_GLOB_PERM_X      = (1<<4);

/*
 * Flags for the unload callback function.
 */
enum TCL_UNLOAD_DETACH_FROM_INTERPRETER = (1<<0);
enum TCL_UNLOAD_DETACH_FROM_PROCESS     = (1<<1);

/*
 * Typedefs for the various filesystem operations:
 */
alias extern(C) int function(Tcl_Obj* pathPtr, Tcl_StatBuf* buf) nothrow Tcl_FSStatProc;
alias extern(C) int function(Tcl_Obj* pathPtr, int mode) nothrow Tcl_FSAccessProc;
alias extern(C) Tcl_Channel function(Tcl_Interp* interp, Tcl_Obj* pathPtr, int mode, int permissions) nothrow Tcl_FSOpenFileChannelProc;
alias extern(C) int function(Tcl_Interp* interp, Tcl_Obj* result, Tcl_Obj* pathPtr, const(char)* pattern, Tcl_GlobTypeData* types) nothrow Tcl_FSMatchInDirectoryProc;
alias extern(C) Tcl_Obj* function(Tcl_Interp* interp) nothrow Tcl_FSGetCwdProc;
alias extern(C) int function(Tcl_Obj* pathPtr) nothrow Tcl_FSChdirProc;
alias extern(C) int function(Tcl_Obj* pathPtr, Tcl_StatBuf* buf) nothrow Tcl_FSLstatProc;
alias extern(C) int function(Tcl_Obj* pathPtr) nothrow Tcl_FSCreateDirectoryProc;
alias extern(C) int function(Tcl_Obj* pathPtr) nothrow Tcl_FSDeleteFileProc;
alias extern(C) int function(Tcl_Obj* srcPathPtr, Tcl_Obj* destPathPtr, Tcl_Obj** errorPtr) nothrow Tcl_FSCopyDirectoryProc;
alias extern(C) int function(Tcl_Obj* srcPathPtr, Tcl_Obj* destPathPtr) nothrow Tcl_FSCopyFileProc;
alias extern(C) int function(Tcl_Obj* pathPtr, int recursive, Tcl_Obj** errorPtr) nothrow Tcl_FSRemoveDirectoryProc;
alias extern(C) int function(Tcl_Obj* srcPathPtr, Tcl_Obj* destPathPtr) nothrow Tcl_FSRenameFileProc;
alias extern(C) void function(Tcl_LoadHandle loadHandle) nothrow Tcl_FSUnloadFileProc;
alias extern(C) Tcl_Obj* function() nothrow Tcl_FSListVolumesProc;

/* We have to declare the utime structure here. */
struct utimbuf;

alias extern(C) int function(Tcl_Obj* pathPtr, utimbuf* tval) nothrow Tcl_FSUtimeProc;
alias extern(C) int function(Tcl_Interp* interp, Tcl_Obj* pathPtr, int nextCheckpoint) nothrow Tcl_FSNormalizePathProc;
alias extern(C) int function(Tcl_Interp* interp, int index, Tcl_Obj* pathPtr, Tcl_Obj** objPtrRef) nothrow Tcl_FSFileAttrsGetProc;
alias extern(C) const(char)** function(Tcl_Obj* pathPtr, Tcl_Obj** objPtrRef) nothrow Tcl_FSFileAttrStringsProc;
alias extern(C) int function(Tcl_Interp* interp, int index, Tcl_Obj* pathPtr, Tcl_Obj* objPtr) nothrow Tcl_FSFileAttrsSetProc;
alias extern(C) Tcl_Obj* function(Tcl_Obj* pathPtr, Tcl_Obj* toPtr, int linkType) nothrow Tcl_FSLinkProc;
alias extern(C) int function(Tcl_Interp* interp, Tcl_Obj* pathPtr, Tcl_LoadHandle* handlePtr, Tcl_FSUnloadFileProc unloadProcPtr) nothrow Tcl_FSLoadFileProc;
alias extern(C) int function(Tcl_Obj* pathPtr, ClientData* clientDataPtr) nothrow Tcl_FSPathInFilesystemProc;
alias extern(C) Tcl_Obj* function(Tcl_Obj* pathPtr) nothrow Tcl_FSFilesystemPathTypeProc;
alias extern(C) Tcl_Obj* function(Tcl_Obj* pathPtr) nothrow Tcl_FSFilesystemSeparatorProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_FSFreeInternalRepProc;
alias extern(C) ClientData function(ClientData clientData) nothrow Tcl_FSDupInternalRepProc;
alias extern(C) Tcl_Obj* function(ClientData clientData) nothrow Tcl_FSInternalToNormalizedProc;
alias extern(C) ClientData function( Tcl_Obj *pathPtr) nothrow Tcl_FSCreateInternalRepProc;

struct Tcl_FSVersion_;
alias Tcl_FSVersion = Tcl_FSVersion_*;

/*
 *----------------------------------------------------------------
 * Data structures related to hooking into the filesystem
 *----------------------------------------------------------------
 */

/*
 * Filesystem version tag.  This was introduced in 8.4.
 */
enum TCL_FILESYSTEM_VERSION_1 = cast(Tcl_FSVersion)0x1;

/*
 * struct Tcl_Filesystem:
 *
 * One such structure exists for each type (kind) of filesystem. It collects
 * together in one place all the functions that are part of the specific
 * filesystem. Tcl always accesses the filesystem through one of these
 * structures.
 *
 * Not all entries need be non-NULL; any which are NULL are simply ignored.
 * However, a complete filesystem should provide all of these functions. The
 * explanations in the structure show the importance of each function.
 */
struct Tcl_Filesystem
{
	/* The name of the filesystem. */
	char *typeName;

	/* Length of this structure, so future binary
	 * compatibility can be assured. */
	int structureLength;

	/* Version of the filesystem type. */
	Tcl_FSVersion version_;

	/* Function to check whether a path is in this
	 * filesystem. This is the most important
	 * filesystem function. */
	Tcl_FSPathInFilesystemProc pathInFilesystemProc;

	/* Function to duplicate internal fs rep. May
	 * be NULL (but then fs is less efficient). */
	Tcl_FSDupInternalRepProc dupInternalRepProc;

	/* Function to free internal fs rep. Must be
	 * implemented if internal representations
	 * need freeing, otherwise it can be NULL. */
	Tcl_FSFreeInternalRepProc freeInternalRepProc;

	/* Function to convert internal representation
	 * to a normalized path. Only required if the
	 * fs creates pure path objects with no
	 * string/path representation. */
	Tcl_FSInternalToNormalizedProc internalToNormalizedProc;

	/* Function to create a filesystem-specific
	 * internal representation. May be NULL if
	 * paths have no internal representation, or
	 * if the Tcl_FSPathInFilesystemProc for this
	 * filesystem always immediately creates an
	 * internal representation for paths it
	 * accepts. */
	Tcl_FSCreateInternalRepProc createInternalRepProc;

	/* Function to normalize a path.  Should be
	 * implemented for all filesystems which can
	 * have multiple string representations for
	 * the same path object. */
	Tcl_FSNormalizePathProc normalizePathProc;

	/* Function to determine the type of a path in
	 * this filesystem. May be NULL. */
	Tcl_FSFilesystemPathTypeProc filesystemPathTypeProc;

	/* Function to return the separator
	 * character(s) for this filesystem. Must be
	 * implemented. */
	Tcl_FSFilesystemSeparatorProc filesystemSeparatorProc;

	/* Function to process a 'Tcl_FSStat()' call.
	 * Must be implemented for any reasonable
	 * filesystem. */
	Tcl_FSStatProc statProc;

	/* Function to process a 'Tcl_FSAccess()'
	 * call. Must be implemented for any
	 * reasonable filesystem. */
	Tcl_FSAccessProc accessProc;

	/* Function to process a
	 * 'Tcl_FSOpenFileChannel()' call. Must be
	 * implemented for any reasonable
	 * filesystem. */
	Tcl_FSOpenFileChannelProc openFileChannelProc;

	/* Function to process a
	 * 'Tcl_FSMatchInDirectory()'.  If not
	 * implemented, then glob and recursive copy
	 * functionality will be lacking in the
	 * filesystem. */
	Tcl_FSMatchInDirectoryProc matchInDirectoryProc;

	/* Function to process a 'Tcl_FSUtime()' call.
	 * Required to allow setting (not reading) of
	 * times with 'file mtime', 'file atime' and
	 * the open-r/open-w/fcopy implementation of
	 * 'file copy'. */
	Tcl_FSUtimeProc utimeProc;

	/* Function to process a 'Tcl_FSLink()' call.
	 * Should be implemented only if the
	 * filesystem supports links (reading or
	 * creating). */
	Tcl_FSLinkProc linkProc;

	/* Function to list any filesystem volumes
	 * added by this filesystem. Should be
	 * implemented only if the filesystem adds
	 * volumes at the head of the filesystem. */
	Tcl_FSListVolumesProc listVolumesProc;

	/* Function to list all attributes strings
	 * which are valid for this filesystem. If not
	 * implemented the filesystem will not support
	 * the 'file attributes' command. This allows
	 * arbitrary additional information to be
	 * attached to files in the filesystem. */
	Tcl_FSFileAttrStringsProc fileAttrStringsProc;

	/* Function to process a
	 * 'Tcl_FSFileAttrsGet()' call, used by 'file
	 * attributes'. */
	Tcl_FSFileAttrsGetProc fileAttrsGetProc;

	/* Function to process a
	 * 'Tcl_FSFileAttrsSet()' call, used by 'file
	 * attributes'.  */
	Tcl_FSFileAttrsSetProc fileAttrsSetProc;

	/* Function to process a
	 * 'Tcl_FSCreateDirectory()' call. Should be
	 * implemented unless the FS is read-only. */
	Tcl_FSCreateDirectoryProc createDirectoryProc;

	/* Function to process a
	 * 'Tcl_FSRemoveDirectory()' call. Should be
	 * implemented unless the FS is read-only. */
	Tcl_FSRemoveDirectoryProc removeDirectoryProc;

	/* Function to process a 'Tcl_FSDeleteFile()'
	 * call. Should be implemented unless the FS
	 * is read-only. */
	Tcl_FSDeleteFileProc deleteFileProc;

	/* Function to process a 'Tcl_FSCopyFile()'
	 * call. If not implemented Tcl will fall back
	 * on open-r, open-w and fcopy as a copying
	 * mechanism, for copying actions initiated in
	 * Tcl (not C). */
	Tcl_FSCopyFileProc copyFileProc;

	/* Function to process a 'Tcl_FSRenameFile()'
	 * call. If not implemented, Tcl will fall
	 * back on a copy and delete mechanism, for
	 * rename actions initiated in Tcl (not C). */
	Tcl_FSRenameFileProc renameFileProc;

	/* Function to process a
	 * 'Tcl_FSCopyDirectory()' call. If not
	 * implemented, Tcl will fall back on a
	 * recursive create-dir, file copy mechanism,
	 * for copying actions initiated in Tcl (not
	 * C). */
	Tcl_FSCopyDirectoryProc copyDirectoryProc;

	/* Function to process a 'Tcl_FSLstat()' call.
	 * If not implemented, Tcl will attempt to use
	 * the 'statProc' defined above instead. */
	Tcl_FSLstatProc lstatProc;

	/* Function to process a 'Tcl_FSLoadFile()'
	 * call. If not implemented, Tcl will fall
	 * back on a copy to native-temp followed by a
	 * Tcl_FSLoadFile on that temporary copy. */
	Tcl_FSLoadFileProc loadFileProc;

	/* Function to process a 'Tcl_FSGetCwd()'
	 * call. Most filesystems need not implement
	 * this. It will usually only be called once,
	 * if 'getcwd' is called before 'chdir'. May
	 * be NULL. */
	Tcl_FSGetCwdProc getCwdProc;

	/* Function to process a 'Tcl_FSChdir()' call.
	 * If filesystems do not implement this, it
	 * will be emulated by a series of directory
	 * access checks. Otherwise, virtual
	 * filesystems which do implement it need only
	 * respond with a positive return result if
	 * the dirName is a valid directory in their
	 * filesystem. They need not remember the
	 * result, since that will be automatically
	 * remembered for use by GetCwd. Real
	 * filesystems should carry out the correct
	 * action (i.e. call the correct system
	 * 'chdir' api). If not implemented, then 'cd'
	 * and 'pwd' will fail inside the
	 * filesystem. */
	Tcl_FSChdirProc chdirProc;
}

/*
 * The following definitions are used as values for the 'linkAction' flag to
 * Tcl_FSLink, or the linkProc of any filesystem. Any combination of flags can
 * be given. For link creation, the linkProc should create a link which
 * matches any of the types given.
 *
 * TCL_CREATE_SYMBOLIC_LINK -	Create a symbolic or soft link.
 * TCL_CREATE_HARD_LINK -	Create a hard link.
 */
enum TCL_CREATE_SYMBOLIC_LINK = 0x01;
enum TCL_CREATE_HARD_LINK     = 0x02;

/*
 * The following structure represents the Notifier functions that you can
 * override with the Tcl_SetNotifier call.
 */
struct Tcl_NotifierProcs
{
	Tcl_SetTimerProc setTimerProc;
	Tcl_WaitForEventProc waitForEventProc;
	Tcl_CreateFileHandlerProc createFileHandlerProc;
	Tcl_DeleteFileHandlerProc deleteFileHandlerProc;
	Tcl_InitNotifierProc initNotifierProc;
	Tcl_FinalizeNotifierProc finalizeNotifierProc;
	Tcl_AlertNotifierProc alertNotifierProc;
	Tcl_ServiceModeHookProc serviceModeHookProc;
}

/*
 * The following data structures and declarations are for the new Tcl parser.
 *
 * For each word of a command, and for each piece of a word such as a variable
 * reference, one of the following structures is created to describe the
 * token.
 */
struct Tcl_Token
{
	/* Type of token, such as TCL_TOKEN_WORD; see
	 * below for valid types. */
	int type;

	/* First character in token. */
	const(char)* start;

	/* Number of bytes in token. */
	int size;

	/* If this token is composed of other tokens,
	 * this field tells how many of them there are
	 * (including components of components, etc.).
	 * The component tokens immediately follow
	 * this one. */
	int numComponents;
}

/*
 * Type values defined for Tcl_Token structures. These values are defined as
 * mask bits so that it's easy to check for collections of types.
 *
 * TCL_TOKEN_WORD -		The token describes one word of a command,
 *				from the first non-blank character of the word
 *				(which may be " or {) up to but not including
 *				the space, semicolon, or bracket that
 *				terminates the word. NumComponents counts the
 *				total number of sub-tokens that make up the
 *				word. This includes, for example, sub-tokens
 *				of TCL_TOKEN_VARIABLE tokens.
 * TCL_TOKEN_SIMPLE_WORD -	This token is just like TCL_TOKEN_WORD except
 *				that the word is guaranteed to consist of a
 *				single TCL_TOKEN_TEXT sub-token.
 * TCL_TOKEN_TEXT -		The token describes a range of literal text
 *				that is part of a word. NumComponents is
 *				always 0.
 * TCL_TOKEN_BS -		The token describes a backslash sequence that
 *				must be collapsed. NumComponents is always 0.
 * TCL_TOKEN_COMMAND -		The token describes a command whose result
 *				must be substituted into the word. The token
 *				includes the enclosing brackets. NumComponents
 *				is always 0.
 * TCL_TOKEN_VARIABLE -		The token describes a variable substitution,
 *				including the dollar sign, variable name, and
 *				array index (if there is one) up through the
 *				right parentheses. NumComponents tells how
 *				many additional tokens follow to represent the
 *				variable name. The first token will be a
 *				TCL_TOKEN_TEXT token that describes the
 *				variable name. If the variable is an array
 *				reference then there will be one or more
 *				additional tokens, of type TCL_TOKEN_TEXT,
 *				TCL_TOKEN_BS, TCL_TOKEN_COMMAND, and
 *				TCL_TOKEN_VARIABLE, that describe the array
 *				index; numComponents counts the total number
 *				of nested tokens that make up the variable
 *				reference, including sub-tokens of
 *				TCL_TOKEN_VARIABLE tokens.
 * TCL_TOKEN_SUB_EXPR -		The token describes one subexpression of an
 *				expression, from the first non-blank character
 *				of the subexpression up to but not including
 *				the space, brace, or bracket that terminates
 *				the subexpression. NumComponents counts the
 *				total number of following subtokens that make
 *				up the subexpression; this includes all
 *				subtokens for any nested TCL_TOKEN_SUB_EXPR
 *				tokens. For example, a numeric value used as a
 *				primitive operand is described by a
 *				TCL_TOKEN_SUB_EXPR token followed by a
 *				TCL_TOKEN_TEXT token. A binary subexpression
 *				is described by a TCL_TOKEN_SUB_EXPR token
 *				followed by the TCL_TOKEN_OPERATOR token for
 *				the operator, then TCL_TOKEN_SUB_EXPR tokens
 *				for the left then the right operands.
 * TCL_TOKEN_OPERATOR -		The token describes one expression operator.
 *				An operator might be the name of a math
 *				function such as "abs". A TCL_TOKEN_OPERATOR
 *				token is always preceeded by one
 *				TCL_TOKEN_SUB_EXPR token for the operator's
 *				subexpression, and is followed by zero or more
 *				TCL_TOKEN_SUB_EXPR tokens for the operator's
 *				operands. NumComponents is always 0.
 * TCL_TOKEN_EXPAND_WORD -	This token is just like TCL_TOKEN_WORD except
 *				that it marks a word that began with the
 *				literal character prefix "{*}". This word is
 *				marked to be expanded - that is, broken into
 *				words after substitution is complete.
 */
enum TCL_TOKEN_WORD        = 1;
enum TCL_TOKEN_SIMPLE_WORD = 2;
enum TCL_TOKEN_TEXT        = 4;
enum TCL_TOKEN_BS          = 8;
enum TCL_TOKEN_COMMAND     = 16;
enum TCL_TOKEN_VARIABLE    = 32;
enum TCL_TOKEN_SUB_EXPR    = 64;
enum TCL_TOKEN_OPERATOR    = 128;
enum TCL_TOKEN_EXPAND_WORD = 256;

/*
 * Parsing error types. On any parsing error, one of these values will be
 * stored in the error field of the Tcl_Parse structure defined below.
 */
enum TCL_PARSE_SUCCESS           = 0;
enum TCL_PARSE_QUOTE_EXTRA       = 1;
enum TCL_PARSE_BRACE_EXTRA       = 2;
enum TCL_PARSE_MISSING_BRACE     = 3;
enum TCL_PARSE_MISSING_BRACKET   = 4;
enum TCL_PARSE_MISSING_PAREN     = 5;
enum TCL_PARSE_MISSING_QUOTE     = 6;
enum TCL_PARSE_MISSING_VAR_BRACE = 7;
enum TCL_PARSE_SYNTAX            = 8;
enum TCL_PARSE_BAD_NUMBER        = 9;

/*
 * A structure of the following type is filled in by Tcl_ParseCommand. It
 * describes a single command parsed from an input string.
 */
enum NUM_STATIC_TOKENS = 20;

struct Tcl_Parse
{
	/* Pointer to # that begins the first of one
	 * or more comments preceding the command. */
	const(char)* commentStart;

	/* Number of bytes in comments (up through
	 * newline character that terminates the last
	 * comment). If there were no comments, this
	 * field is 0. */
	int commentSize;

	/* First character in first word of
	 * command. */
	const(char)* commandStart;

	/* Number of bytes in command, including first
	 * character of first word, up through the
	 * terminating newline, close bracket, or
	 * semicolon. */
	int commandSize;

	/* Total number of words in command. May be
	 * 0. */
	int numWords;

	/* Pointer to first token representing the
	 * words of the command. Initially points to
	 * staticTokens, but may change to point to
	 * malloc-ed space if command exceeds space in
	 * staticTokens. */
	Tcl_Token* tokenPtr;

	/* Total number of tokens in command. */
	int numTokens;

	/* Total number of tokens available at
	 * *tokenPtr. */
	int tokensAvailable;

	/* One of the parsing error types defined
	 * above. */
	int errorType;

	/*
	 * The fields below are intended only for the private use of the parser.
	 * They should not be used by functions that invoke Tcl_ParseCommand.
	 */

	/* The original command string passed to
	 * Tcl_ParseCommand. */
	const(char)* string;

	/* Points to the character just after the last
	 * one in the command string. */
	const(char)* end;

	/* Interpreter to use for error reporting, or
	 * NULL. */
	Tcl_Interp* interp;

	/* Points to character in string that
	 * terminated most recent token. Filled in by
	 * ParseTokens. If an error occurs, points to
	 * beginning of region where the error
	 * occurred (e.g. the open brace if the close
	 * brace is missing). */
	const(char)* term;

	/* This field is set to 1 by Tcl_ParseCommand
	 * if the command appears to be incomplete.
	 * This information is used by
	 * Tcl_CommandComplete. */
	int incomplete;

	/* Initial space for tokens for command. This
	 * space should be large enough to accommodate
	 * most commands; dynamic space is allocated
	 * for very large commands that don't fit
	 * here. */
	Tcl_Token[NUM_STATIC_TOKENS] staticTokens;
}

/*
 * The following structure represents a user-defined encoding. It collects
 * together all the functions that are used by the specific encoding.
 */
struct Tcl_EncodingType
{
	/* The name of the encoding, e.g. "euc-jp".
	 * This name is the unique key for this
	 * encoding type. */
	const(char)* encodingName;

	/* Function to convert from external encoding
	 * into UTF-8. */
	Tcl_EncodingConvertProc toUtfProc;

	/* Function to convert from UTF-8 into
	 * external encoding. */
	Tcl_EncodingConvertProc fromUtfProc;

	/* If non-NULL, function to call when this
	 * encoding is deleted. */
	Tcl_EncodingFreeProc freeProc;

	/* Arbitrary value associated with encoding
	 * type. Passed to conversion functions. */
	ClientData clientData;

	/* Number of zero bytes that signify
	 * end-of-string in this encoding. This number
	 * is used to determine the source string
	 * length when the srcLen argument is
	 * negative. Must be 1 or 2. */
	int nullSize;
}

/*
 * The following definitions are used as values for the conversion control
 * flags argument when converting text from one character set to another:
 *
 * TCL_ENCODING_START - Signifies that the source buffer is the first
 *				block in a (potentially multi-block) input
 *				stream. Tells the conversion function to reset
 *				to an initial state and perform any
 *				initialization that needs to occur before the
 *				first byte is converted. If the source buffer
 *				contains the entire input stream to be
 *				converted, this flag should be set.
 * TCL_ENCODING_END - Signifies that the source buffer is the last
 *				block in a (potentially multi-block) input
 *				stream. Tells the conversion routine to
 *				perform any finalization that needs to occur
 *				after the last byte is converted and then to
 *				reset to an initial state. If the source
 *				buffer contains the entire input stream to be
 *				converted, this flag should be set.
 * TCL_ENCODING_STOPONERROR - If set, then the converter will return
 *				immediately upon encountering an invalid byte
 *				sequence or a source character that has no
 *				mapping in the target encoding. If clear, then
 *				the converter will skip the problem,
 *				substituting one or more "close" characters in
 *				the destination buffer and then continue to
 *				convert the source.
 */
enum TCL_ENCODING_START       = 0x01;
enum TCL_ENCODING_END         = 0x02;
enum TCL_ENCODING_STOPONERROR = 0x04;

/*
 * The following definitions are the error codes returned by the conversion
 * routines:
 *
 * TCL_OK - All characters were converted.
 * TCL_CONVERT_NOSPACE - The output buffer would not have been large
 *				enough for all of the converted data; as many
 *				characters as could fit were converted though.
 * TCL_CONVERT_MULTIBYTE - The last few bytes in the source string were
 *				the beginning of a multibyte sequence, but
 *				more bytes were needed to complete this
 *				sequence. A subsequent call to the conversion
 *				routine should pass the beginning of this
 *				unconverted sequence plus additional bytes
 *				from the source stream to properly convert the
 *				formerly split-up multibyte sequence.
 * TCL_CONVERT_SYNTAX - The source stream contained an invalid
 *				character sequence. This may occur if the
 *				input stream has been damaged or if the input
 *				encoding method was misidentified. This error
 *				is reported only if TCL_ENCODING_STOPONERROR
 *				was specified.
 * TCL_CONVERT_UNKNOWN - The source string contained a character that
 *				could not be represented in the target
 *				encoding. This error is reported only if
 *				TCL_ENCODING_STOPONERROR was specified.
 */
enum TCL_CONVERT_MULTIBYTE = (-1);
enum TCL_CONVERT_SYNTAX    = (-2);
enum TCL_CONVERT_UNKNOWN   = (-3);
enum TCL_CONVERT_NOSPACE   = (-4);

/*
 * The maximum number of bytes that are necessary to represent a single
 * Unicode character in UTF-8. The valid values should be 3, 4 or 6
 * (or perhaps 1 if we want to support a non-unicode enabled core). If 3 or
 * 4, then Tcl_UniChar must be 2-bytes in size (UCS-2) (the default). If 6,
 * then Tcl_UniChar must be 4-bytes in size (UCS-4). At this time UCS-2 mode
 * is the default and recommended mode. UCS-4 is experimental and not
 * recommended. It works for the core, but most extensions expect UCS-2.
 */
enum TCL_UTF_MAX = 3;

/*
 * This represents a Unicode character. Any changes to this should also be
 * reflected in regcustom.h.
 */
static if (TCL_UTF_MAX > 4)
{
	/*
	 * unsigned int isn't 100% accurate as it should be a strict 4-byte value
	 * (perhaps wchar_t). 64-bit systems may have troubles. The size of this
	 * value must be reflected correctly in regcustom.h and
	 * in tclEncoding.c.
	 * XXX: Tcl is currently UCS-2 and planning UTF-16 for the Unicode
	 * XXX: string rep that Tcl_UniChar represents.  Changing the size
	 * XXX: of Tcl_UniChar is /not/ supported.
	 */
	alias Tcl_UniChar = uint;
}
else
{
	alias Tcl_UniChar = ushort;
}

/*
 * TIP #59: The following structure is used in calls 'Tcl_RegisterConfig' to
 * provide the system with the embedded configuration data.
 */
struct Tcl_Config
{
    const(char)* key;   /* Configuration key to register. ASCII encoded, thus UTF-8. */
    const(char)* value; /* The value associated with the key. System encoding. */
}

/*
 * Flags for TIP#143 limits, detailing which limits are active in an
 * interpreter. Used for Tcl_{Add,Remove}LimitHandler type argument.
 */
enum TCL_LIMIT_COMMANDS = 0x01;
enum TCL_LIMIT_TIME     = 0x02;

/*
 * Structure containing information about a limit handler to be called when a
 * command- or time-limit is exceeded by an interpreter.
 */
alias extern(C) void function(ClientData clientData, Tcl_Interp* interp) nothrow Tcl_LimitHandlerProc;
alias extern(C) void function(ClientData clientData) nothrow Tcl_LimitHandlerDeleteProc;

/*
 * Override definitions for libtommath.
 */
struct mp_int;
alias mp_digit = uint;

/*
 * Definitions needed for Tcl_ParseArgvObj routines.
 * Based on tkArgv.c.
 * Modifications from the original are copyright (c) Sam Bromley 2006
 */

struct Tcl_ArgvInfo
{
	/* Indicates the option type; see below. */
    int type;

	/* The key string that flags the option in the argv array. */
    const(char)* keyStr;

	/* Value to be used in setting dst; usage depends on type.*/
    void* srcPtr;

	/* Address of value to be modified; usage depends on type.*/
    void* dstPtr;

	/* Documentation message describing this option. */
    const(char)* helpStr;

	/* Word to pass to function callbacks. */
    ClientData clientData;
}

/*
 * Legal values for the type field of a Tcl_ArgInfo: see the user
 * documentation for details.
 */
enum TCL_ARGV_CONSTANT = 15;
enum TCL_ARGV_INT      = 16;
enum TCL_ARGV_STRING   = 17;
enum TCL_ARGV_REST     = 18;
enum TCL_ARGV_FLOAT    = 19;
enum TCL_ARGV_FUNC     = 20;
enum TCL_ARGV_GENFUNC  = 21;
enum TCL_ARGV_HELP     = 22;
enum TCL_ARGV_END      = 23;

/*
 * Types of callback functions for the TCL_ARGV_FUNC and TCL_ARGV_GENFUNC
 * argument types:
 */
alias extern(C) int function(ClientData clientData, Tcl_Obj* objPtr, void* dstPtr) nothrow Tcl_ArgvFuncProc;
alias extern(C) int function(ClientData clientData, Tcl_Interp *interp, int objc, const(Tcl_Obj*)* objv, void *dstPtr) nothrow Tcl_ArgvGenFuncProc;

/*
 * Definitions needed for Tcl_Zlib routines. [TIP #234]
 *
 * Constants for the format flags describing what sort of data format is
 * desired/expected for the Tcl_ZlibDeflate, Tcl_ZlibInflate and
 * Tcl_ZlibStreamInit functions.
 */
enum TCL_ZLIB_FORMAT_RAW  = 1;
enum TCL_ZLIB_FORMAT_ZLIB = 2;
enum TCL_ZLIB_FORMAT_GZIP = 4;
enum TCL_ZLIB_FORMAT_AUTO = 8;

/*
 * Constants that describe whether the stream is to operate in compressing or
 * decompressing mode.
 */
enum TCL_ZLIB_STREAM_DEFLATE = 16;
enum TCL_ZLIB_STREAM_INFLATE = 32;

/*
 * Constants giving compression levels. Use of TCL_ZLIB_COMPRESS_DEFAULT is
 * recommended.
 */
enum TCL_ZLIB_COMPRESS_NONE    = 0;
enum TCL_ZLIB_COMPRESS_FAST    = 1;
enum TCL_ZLIB_COMPRESS_BEST    = 9;
enum TCL_ZLIB_COMPRESS_DEFAULT = (-1);

/*
 * Constants for types of flushing, used with Tcl_ZlibFlush.
 */
enum TCL_ZLIB_NO_FLUSH  = 0;
enum TCL_ZLIB_FLUSH     = 2;
enum TCL_ZLIB_FULLFLUSH = 3;
enum TCL_ZLIB_FINALIZE  = 4;

/*
 * Definitions needed for the Tcl_LoadFile function. [TIP #416]
 */
enum TCL_LOAD_GLOBAL = 1;
enum TCL_LOAD_LAZY   = 2;

/*
 * Single public declaration for NRE.
 */
alias extern(C) int function(ClientData data[], Tcl_Interp* interp, int result) nothrow Tcl_NRPostProc;

/*
 * The following constant is used to test for older versions of Tcl in the
 * stubs tables.
 *
 * Jan Nijtman's plus patch uses 0xFCA1BACF, so we need to pick a different
 * value since the stubs tables don't match.
 */
enum TCL_STUB_MAGIC = 0xFCA3BACF;

/*
 * The following function is required to be defined in all stubs aware
 * extensions. The function is actually implemented in the stub library, not
 * the main Tcl library, although there is a trivial implementation in the
 * main library in case an extension is statically linked into an application.
 */
extern(C) const(char)* Tcl_InitStubs(Tcl_Interp* interp, const(char)* version_, int exact) nothrow;
extern(C) const(char)* TclTomMathInitializeStubs(Tcl_Interp* interp, const(char)* version_, int epoch, int revision) nothrow;

/*
 * When not using stubs, make it a macro.
 */

/*
 * TODO - tommath stubs export goes here!
 */

/*
 * Public functions that are not accessible via the stubs table.
 * Tcl_GetMemoryInfo is needed for AOLserver. [Bug 1868171]
 */
void Tcl_Main(int argc, const(char)** argv, Tcl_AppInitProc appInitProc) nothrow
{
	Tcl_MainEx(argc, argv, appInitProc, Tcl_CreateInterp());
}

extern(C) void Tcl_MainEx(int argc, const(char)** argv, Tcl_AppInitProc appInitProc, Tcl_Interp* interp) nothrow;
extern(C) const(char)* Tcl_PkgInitStubsCheck(Tcl_Interp* interp, const(char)* version_, int exact) nothrow;
extern(C) void Tcl_GetMemoryInfo(Tcl_DString* dsPtr) nothrow;

/*
 * Include the public function declarations that are accessible via the stubs
 * table.
 */
public import tcltk.tcldecls;

/*
 * Include platform specific public function declarations that are accessible
 * via the stubs table.
 */
public import tcltk.tclplatdecls;

/*
 * The following declarations either map ckalloc and ckfree to malloc and
 * free, or they map them to functions with all sorts of debugging hooks
 * defined in tclCkalloc.c.
 */
version(TCL_MEM_DEBUG)
{
	void* ckalloc(uint size, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbCkalloc(size, cast(char*)file.toStringz, cast(int)line);
	}

	int ckfree(const(char)* ptr, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		Tcl_DbCkfree(ptr, cast(char*)file.toStringz, cast(int)line);
	}

	void* ckrealloc(const(char)* ptr, uint size, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbCkrealloc(ptr, size, cast(char*)file.toStringz, cast(int)line);
	}

	void* attemptckalloc(uint size, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_AttemptDbCkalloc(size, cast(char*)file.toStringz, cast(int)line);
	}

	void* attemptckrealloc(const(char)* ptr, uint size, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_AttemptDbCkrealloc(ptr, size, cast(char*)file.toStringz, cast(int)line);
	}
}
else
{
	/*
	 * If we are not using the debugging allocator, we should call the Tcl_Alloc,
	 * et al. routines in order to guarantee that every module is using the same
	 * memory allocator both inside and outside of the Tcl library.
	 */

	void* ckalloc(uint size) nothrow
	{
		return Tcl_Alloc(size);
	}

	void ckfree(const(char)* ptr) nothrow
	{
		Tcl_Free(ptr);
	}

	void* ckrealloc(const(char)* ptr, uint size) nothrow
	{
		return Tcl_Realloc(ptr, size);
	}

	void* attemptckalloc(uint size) nothrow
	{
		return Tcl_AttemptAlloc(size);
	}

	void* attemptckrealloc(const(char)* ptr, uint size) nothrow
	{
		return Tcl_AttemptRealloc(ptr, size);
	}
}

/*
 * Macros to increment and decrement a Tcl_Obj's reference count, and to test
 * whether an object is shared (i.e. has reference count > 1). Note: clients
 * should use Tcl_DecrRefCount() when they are finished using an object, and
 * should never call TclFreeObj() directly. TclFreeObj() is only defined and
 * made public in tcl.h to support Tcl_DecrRefCount's macro definition. Note
 * also that Tcl_DecrRefCount() refers to the parameter "obj" twice. This
 * means that you should avoid calling it with an expression that is expensive
 * to compute or has side effects.
 */
version(TCL_MEM_DEBUG)
{
	void Tcl_IncrRefCount(Tcl_Obj* objPtr, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		Tcl_DbIncrRefCount(objPtr, cast(char*)file.toStringz, cast(int)line);
	}

	void Tcl_DecrRefCount(Tcl_Obj* objPtr, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		Tcl_DbDecrRefCount(objPtr, cast(char*)file.toStringz, cast(int)line);
	}

	int Tcl_IsShared(Tcl_Obj* objPtr, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbIsShared(objPtr, cast(char*)file.toStringz, cast(int)line);
	}
}
else
{
	// extern(C) void Tcl_IncrRefCount(Tcl_Obj* objPtr) nothrow;
	// extern(C) void Tcl_DecrRefCount(Tcl_Obj* objPtr) nothrow;
	// extern(C) int Tcl_IsShared(Tcl_Obj* objPtr) nothrow;

	void Tcl_IncrRefCount(Tcl_Obj* objPtr) nothrow
	{
		++(*objPtr).refCount;
	}

	void Tcl_DecrRefCount(Tcl_Obj* objPtr) nothrow
	{
		if (--(*objPtr).refCount <= 0)
		{
			TclFreeObj(objPtr);
		}
	}

	int Tcl_IsShared(Tcl_Obj* objPtr) nothrow
	{
		return (*objPtr).refCount > 1;
	}
}

/*
 * Macros and definitions that help to debug the use of Tcl objects. When
 * TCL_MEM_DEBUG is defined, the Tcl_New declarations are overridden to call
 * debugging versions of the object creation functions.
 */
version(TCL_MEM_DEBUG)
{
	Tcl_Obj* Tcl_NewBignumObj(mp_int* value, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewBignumObj(value, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewBooleanObj(int booleanValue, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewBooleanObj(booleanValue, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewByteArrayObj(ubyte* bytes, int length, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewByteArrayObj(bytes, length, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewDoubleObj(double doubleValue, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewDoubleObj(doubleValue, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewIntObj(int intValue, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewLongObj(intValue, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewListObj(int objc, const(Tcl_Obj*)* objv, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewListObj(objc, objv, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewLongObj(c_long longValue, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewLongObj(longValue, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewObj(string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewObj(cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewStringObj(const(char)* bytes, int length, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewStringObj(bytes, length, cast(char*)file.toStringz, cast(int)line);
	}

	Tcl_Obj* Tcl_NewWideIntObj(Tcl_WideInt wideValue, string file = __FILE__, size_t line = __LINE__) nothrow
	{
		return Tcl_DbNewWideIntObj(wideValue, cast(char*)file.toStringz, cast(int)line);
	}
}

/*
 * Macros for clients to use to access fields of hash entries:
 */
ClientData Tcl_GetHashValue(Tcl_HashEntry* h) nothrow
{
	return (*h).clientData;
}

void Tcl_SetHashValue(Tcl_HashEntry* h, ClientData c) nothrow
{
	(*h).clientData = c;
}

void* Tcl_GetHashKey(Tcl_HashTable* tablePtr, Tcl_HashEntry* h) nothrow
{
	if ((*tablePtr).keyType == TCL_ONE_WORD_KEYS || (*tablePtr).keyType == TCL_CUSTOM_PTR_KEYS)
	{
		return cast(void*)(*h).key.oneWordValue;
	}
	return cast(void*)&((*h).key.string_[0]);
}

/*
 * Macros to use for clients to use to invoke find and create functions for
 * hash tables:
 */
Tcl_HashEntry* Tcl_FindHashEntry(Tcl_HashTable* tablePtr, const(char)* key) nothrow
{
	return (*tablePtr).findProc(tablePtr, key);
}

Tcl_HashEntry* Tcl_CreateHashEntry(Tcl_HashTable* tablePtr, const(char)* key, int* newPtr)
{
	return (*tablePtr).createProc(tablePtr, key, newPtr);
}

/*
 * Convenience declaration of Tcl_AppInit for backwards compatibility. This
 * function is not *implemented* by the tcl library, so the storage class is
 * neither DLLEXPORT nor DLLIMPORT.
 */
extern(C) int Tcl_AppInit(Tcl_Interp* interp) nothrow;
