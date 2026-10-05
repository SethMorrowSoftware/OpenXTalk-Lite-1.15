/* Copyright (C) 2026 OpenXTalk Contributors.

This file is part of LiveCode / OpenXTalk.

LiveCode is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License v3 as published by the Free
Software Foundation. */

// Not Tom Perry's: see CHANGES-FROM-TOM.md, section 2.
//
// On macOS his desktop.cpp, which every desktop engine compiles, calls the
// two functions below from the main loop. His respring.cpp, which defines
// them, is compiled only into the development engine (as in his Xcode
// projects), so the standalone and installer engines do not link. They
// have no "_internal respring" (internal_development.cpp, development
// engine only), so no respring can ever be pending in them; these
// definitions say just that.

#include "prefix.h"

#if defined(_MACOSX)

Boolean MCRespringIsPending(void)
{
	return False;
}

Boolean MCRespringDoRespring(void)
{
	return False;
}

#endif
