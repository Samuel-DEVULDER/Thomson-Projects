
10 CLS
20 ?"'Fast' version (253bytes of RAM)...":?
30 LOADM "PIRAT.BIN",,R
35 ?"Press a key...";:A$=INPUT$(1):CLS
40 ?"Very slow version (128bytes of RAM)...":?
50 LOADM "SPIGOT.BIN",,R
