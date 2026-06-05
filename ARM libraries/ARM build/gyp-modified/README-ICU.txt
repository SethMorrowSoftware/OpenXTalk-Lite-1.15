ICU GYP MODIFICATION FOR ARM BUILDS
====================================

File: libicu.gyp
Location: prebuilt/libicu.gyp

CHANGE MADE:
------------

Line 309: Changed Python path
FROM: '../thirdparty/python2/local-python/bin/python'
TO:   'python2'

REASON:
-------
The gyp-generated script uses 'exec python' which doesn't exist
on systems where Python 2 is named 'python2'. Using 'python2'
directly works because it's in the system PATH.

This change was already applied to:
/Users/admin/Cascade/Livecode-Community-9.6.3/livecode/prebuilt/libicu.gyp

The modified version is saved here for reference.

NOTE:
-----
This modification is already in the source file, so no setup
script is needed. The change is permanent for ARM builds.
