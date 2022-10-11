@echo off
REM This builds all the libraries of the folder for 1 uname

call tecmake %1 %2 %3 %4 %5 %6 %7 %8

if "%1"==""         goto luaexe
if "%1"=="mingw4"   goto luaexe
if "%1"=="vc9_64"   goto luaexe_64
if "%1"=="cygw15"   goto luaexe_cygw15
if "%1"=="cygw17"   goto luaexe_cygw17
if "%1"=="dll9_64"  goto luadll9_64
if "%1"=="dllw4"    goto luadllw4
if "%1"=="all"      goto luaexe
goto end

:luaexe
call tecmake mingw4 "MF=lua" %2 %3 %4 %5 %6 %7
call tecmake mingw4 "MF=wlua" %2 %3 %4 %5 %6 %7
call tecmake mingw4 "MF=luac" %2 %3 %4 %5 %6 %7
call tecmake mingw4 "MF=bin2c" %2 %3 %4 %5 %6 %7
if "%1"=="all"  goto luaexe_64
goto end

:luaexe_64
call tecmake vc9_64 "MF=lua" %2 %3 %4 %5 %6 %7
call tecmake vc9_64 "MF=wlua" %2 %3 %4 %5 %6 %7
call tecmake vc9_64 "MF=luac" %2 %3 %4 %5 %6 %7
call tecmake vc9_64 "MF=bin2c" %2 %3 %4 %5 %6 %7
if "%1"=="all"  goto luaexe_cygw17
goto end

:luaexe_cygw15
call tecmake cygw15 "MF=lua" %2 %3 %4 %5 %6 %7
call tecmake cygw15 "MF=wlua" %2 %3 %4 %5 %6 %7
call tecmake cygw15 "MF=luac" %2 %3 %4 %5 %6 %7
call tecmake cygw15 "MF=bin2c" %2 %3 %4 %5 %6 %7
goto end

:luaexe_cygw17
call tecmake cygw17 "MF=lua" %2 %3 %4 %5 %6 %7
call tecmake cygw17 "MF=wlua" %2 %3 %4 %5 %6 %7
call tecmake cygw17 "MF=luac" %2 %3 %4 %5 %6 %7
call tecmake cygw17 "MF=bin2c" %2 %3 %4 %5 %6 %7
if "%1"=="all"  goto luadll9_64
goto end

:luadll9_64
copy /Y ..\lib\dll9_64\*.dll* ..\bin\Win64\
if "%1"=="all"  goto luadll9
goto end

:luadllw4
copy /Y ..\lib\dllw4\*.dll* ..\bin\Win32\
goto end

:end
