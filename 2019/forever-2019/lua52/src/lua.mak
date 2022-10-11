SFX = 52
APPNAME = lua$(SFX)

SRC = lua.c

include lua_conf.inc

ifneq ($(findstring Win, $(TEC_SYSNAME)), )
  SRC += lua.rc 
  GEN_MANIFEST = Yes
endif
