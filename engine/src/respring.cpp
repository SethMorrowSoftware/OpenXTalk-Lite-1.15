/* Copyright (C) 2024-2026 OpenXTalk Contributors.

This file is part of LiveCode / OpenXTalk.

LiveCode is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License v3 as published by the Free
Software Foundation. */

////////////////////////////////////////////////////////////////////////////////
//
//  Private Source File:
//    respring.cpp
//
//  Description:
//    Implementation of _internal respring command.
//    Closes all stacks, clears per-session state, and reloads the
//    home stack from scratch — an in-process restart without quitting.
//
//    Usage from script:
//      _internal respring
//
//    The command works in two phases:
//      1. exec_ctxt sets a global flag and triggers MCquit/MCexitall
//         to safely unwind the handler chain (same mechanism as quit).
//      2. MCRespringDoRespring() is called from the main loop after
//         the handler chain has fully unwound. It performs the actual
//         teardown and reload.
//
//    This is a cross-platform function that works on macOS, Windows,
//    and Linux. It only touches the stack layer — all engine
//    infrastructure (screen, fonts, graphics, templates, extensions,
//    printer, theme) is left intact.
//
////////////////////////////////////////////////////////////////////////////////

#include "prefix.h"

#include "globdefs.h"
#include "objdefs.h"
#include "parsedef.h"
#include "filedefs.h"
#include "mcio.h"

#include "exec.h"
#include "handler.h"
#include "scriptpt.h"
#include "newobj.h"
#include "cmds.h"
#include "mcerror.h"
#include "globals.h"
#include "express.h"
#include "internal.h"
#include "debug.h"

#include "dispatch.h"
#include "stack.h"
#include "stacklst.h"
#include "cardlst.h"
#include "sellst.h"
#include "undolst.h"
#include "image.h"
#include "osspec.h"

#include "respring.h"

////////////////////////////////////////////////////////////////////////////////

// Global flag: set by exec_ctxt, checked by the main loop.
static Boolean s_respring_pending = False;

Boolean MCRespringIsPending(void)
{
    return s_respring_pending;
}

////////////////////////////////////////////////////////////////////////////////

extern void send_startup_message(bool p_do_relaunch = true);

////////////////////////////////////////////////////////////////////////////////

MCInternalRespring::MCInternalRespring(void)
{
}

MCInternalRespring::~MCInternalRespring(void)
{
}

Parse_stat MCInternalRespring::parse(MCScriptPoint& sp)
{
    return PS_NORMAL;
}

void MCInternalRespring::exec_ctxt(MCExecContext &ctxt)
{
    // Set the respring flag. The actual work happens in
    // MCRespringDoRespring() after the handler chain has unwound.
    s_respring_pending = True;

    // Trigger the same quit/exitall mechanism the engine uses for
    // the "quit" command. This causes MCHandler::exec to break out
    // of its statement loop and unwind cleanly back to X_main_loop.
    MCquit = True;
    MCexitall = True;
    MCtracestackptr = nil;
    MCtraceabort = True;
    MCtracereturn = True;
}

////////////////////////////////////////////////////////////////////////////////
//
//  MCRespringDoRespring — called from the main loop after the handler
//  chain has fully unwound (MCquit caused X_main_loop to exit).
//
//  Phase 1: Teardown — close all stacks and clear per-session state.
//  Phase 2: Reload — re-run startup() to load the home stack afresh.
//
//  Returns true on success, false on failure.
//
////////////////////////////////////////////////////////////////////////////////

Boolean MCRespringDoRespring(void)
{
    // Clear the pending flag
    s_respring_pending = False;

    //
    // Phase 1: Teardown
    //

    // Lock messages so no scripts fire during teardown
    MClockmessages = True;

    // Close all open stack windows (MCstacks is the open-window list)
    if (MCstacks != nil)
        MCstacks->closeall();

    // Drain the pending-destroy list
    if (MCtodestroy != nil && !MCtodestroy->isempty())
        MCtodestroy->destroy();

    // Clear selection and undo state
    if (MCselected != nil)
        MCselected->clear(False);
    if (MCundos != nil)
        MCundos->freestate();

    // Clear card history lists
    if (MCrecent != nil)
    {
        delete MCrecent;
        MCrecent = new (nothrow) MCCardlist;
    }
    if (MCcstack != nil)
    {
        delete MCcstack;
        MCcstack = new (nothrow) MCCardlist;
    }

    // Clear front/backscript lists (these are object reference chains)
    while (MCfrontscripts != nil)
    {
        MCObjectList *t_next = MCfrontscripts->next();
        delete MCfrontscripts;
        MCfrontscripts = (t_next == MCfrontscripts) ? nil : t_next;
    }
    MCfrontscripts = nil;

    while (MCbackscripts != nil)
    {
        MCObjectList *t_next = MCbackscripts->next();
        delete MCbackscripts;
        MCbackscripts = (t_next == MCbackscripts) ? nil : t_next;
    }
    MCbackscripts = nil;

    // Null out all global stack handle pointers
    MCtopstackptr = nil;
    MCdefaultstackptr = nil;
    MCstaticdefaultstackptr = nil;
    MCmousestackptr = nil;
    MCclickstackptr = nil;
    MCfocusedstackptr = nil;

    // Clear the message stack reference on the audio clip pointer
    if (MCacptr.IsValid())
        MCacptr->setmessagestack(NULL);

    // Destroy all loaded stacks from the dispatcher's internal list.
    // This deletes all mainstack and substack objects but keeps the
    // dispatcher itself alive.
    MCdispatcher->clearstacks();

    // Reset image cache
    MCCachedImageRep::init();

    //
    // Phase 2: Reload
    //

    // Reset quit/exit flags so the engine doesn't shut down
    MCquit = False;
    MCexitall = False;
    MCtraceabort = False;
    MCtracereturn = False;

    // Unlock messages before startup (scripts need to run)
    MClockmessages = False;

    // Clear the result
    MCresult->clear();

    // Re-run the dispatcher's startup sequence.
    // In development mode this decompresses and loads the embedded
    // startup stack (the IDE environment stack).
    IO_stat t_stat;
    t_stat = MCdispatcher->startup();
    if (t_stat != IO_NORMAL)
        return False;

    return True;
}
