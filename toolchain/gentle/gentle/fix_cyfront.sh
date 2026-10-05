#!/bin/bash

# Fix all old-style K&R C function declarations in cyfront.c

FILE="cyfront.c"
BACKUP="cyfront.c.backup"

# Create backup
cp "$FILE" "$BACKUP"

# Fix patterns:
# Pattern 1: yyeq_XXX(t1, t2) yy t1, t2; -> int yyeq_XXX(yy t1, yy t2)
sed -i '' 's/^\(yyeq_[A-Z]*\)(t1, t2) yy t1, t2;$/int \1(yy t1, yy t2)/' "$FILE"

# Pattern 2: yyPrint_XXX(t) yy t; -> void yyPrint_XXX(yy t)
sed -i '' 's/^\(yyPrint_[A-Z]*\)(t) yy t;$/void \1(yy t)/' "$FILE"

# Pattern 3: yybroadcast_XXX(t,In,Out,Handler) followed by yy t, In, *Out; int (*Handler) ();
# This is a two-line pattern, more complex
perl -i -p0e 's/^(yybroadcast_[A-Z]+)\(t,In,Out,Handler\)\nyy t, In, \*Out; int \(\*Handler\) \(\);/void $1(yy t, yy In, yy *Out, int (*Handler) ())/gm' "$FILE"

echo "Fixed cyfront.c function declarations"
