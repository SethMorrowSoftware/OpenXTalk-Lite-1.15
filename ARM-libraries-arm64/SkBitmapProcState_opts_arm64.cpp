/*
 * ARM64 platform-specific optimizations for SkBitmapProcState
 */

#include "SkBitmapProcState.h"

// Provide the platformProcs implementation for ARM64
void SkBitmapProcState::platformProcs() {
    // ARM64 uses NEON optimizations which are already set up
    // This function just needs to exist for linking
}
