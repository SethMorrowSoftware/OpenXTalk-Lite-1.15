/*
 * Stub for pixman x86 implementations on ARM64
 * Cairo was built with x86 support enabled, but we're on ARM64
 * This provides a stub that returns NULL (no x86 implementations available)
 */

#include <stddef.h>

typedef struct pixman_implementation pixman_implementation_t;

pixman_implementation_t *
_pixman_x86_get_implementations(pixman_implementation_t *imp)
{
    /* No x86 implementations available on ARM64 */
    return imp;
}
