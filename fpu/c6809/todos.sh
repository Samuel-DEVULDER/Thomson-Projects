#!/bin/sh
#
# todos.sh :
# Convert files from Unix (LF) or Macintosh (CR) to Windows/MS-DOS (CRLF)
# Written by Prehisto
# with the help of Postmortem from https://forum.ubuntu-fr.org/
# Please make tests before using

find . -type f '(' \
   -name '*.c' -o \
   -name '*.h' -o \
   -name 'makefile.*' -o \
   -name '*.txt' -o \
   -name '*.bat' -o \
   -name '*.BAT'\
   ')' \
   -exec sh -c 'printf '\'\\r%s%15s\\r\'' {} '\'\'';
                grep -q $(printf '\'\\r\'') {};
                if [ $? -eq 0 ];
                then
                    mv {} _tmpfile;
                    tr -d '\'\\n\'' < _tmpfile > _tmpfile2;
                    tr '\'\\r\'' '\'\\n\'' < _tmpfile2 > {};
                    touch -r _tmpfile {};
                    rm _tmpfile2;
                    rm _tmpfile;
                fi;
                mv {} _tmpfile;
                sed '\'s/\$/\\r/\'' _tmpfile > {};
                touch -r _tmpfile {};
                rm _tmpfile' \;
echo

