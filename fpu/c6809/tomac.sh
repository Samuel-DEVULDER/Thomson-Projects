#!/bin/sh
#
# tomac.sh :
# Convert files from Unix (LF) or Windows/MS-DOS (CRLF) to Macintosh (CR)
# Written by Prehisto
# with the help of Postmortem from https://forum.ubuntu-fr.org/
# Please make tests before using

find . -type f '(' \
   -name '*.c' -o \
   -name '*.h' -o \
   -name 'makefile.*' -o \
   -name '*.txt' -o \
   -name '*.bat' -o \
   -name '*.BAT' \
   ')' \
   -exec sh -c 'mv {} _tmpfile;
                printf '\'\\r%s%15s\\r\'' {} '\'\'';
                grep -q $(printf '\'\\r\'') _tmpfile;
                if [ $? -eq 0 ];
                then
                    tr -d '\'\\n\'' < _tmpfile > {};
                else
                    tr '\'\\n\'' '\'\\r\'' < _tmpfile > {};
                fi;
                touch -r _tmpfile {};
                rm _tmpfile' \;
echo

