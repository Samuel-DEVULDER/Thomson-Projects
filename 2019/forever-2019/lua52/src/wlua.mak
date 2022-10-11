SFX = 52
APPNAME = wlua$(SFX)

SRC = lua.c wmain.c

include lua_conf.inc

APPTYPE = windows

ifneq ($(findstring Win, $(TEC_SYSNAME)), )
  SRC += wlua.rc 
  GEN_MANIFEST = No
endif
