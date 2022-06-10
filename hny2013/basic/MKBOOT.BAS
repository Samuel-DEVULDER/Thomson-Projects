
10 'SAVE "MKBOOT",A
15 Input "Installer HNY2013 sur B: ? (oui/non) ", R$: IF R$<>"oui" THEN END ELSE DSKINI1
20 CLEAR 1000,&HA1FF
30 DEFINT A-Z
40 M=-&H6000+&H200 '&HA200
50 FORI=0 TO 255:POKEM+I,0:NEXT
60 F$=DSKI$(1,20,2)
70 IF MID$(F$,2,1)<>CHR$(255) THEN INPUT "Boot block occupBe, continuer? (oui/non) ", R$: IF R$<>"oui" THEN PRINT"Abandon":END
80 'reservation FAT
90 MID$(F$,2,1) = CHR$(254)
100 DSKO$ 1,20,2,F$
110 'boot
120 LOADM "bootblk.BIN",M-&H6200
140 'signature + checksum
150 FOR I=0 TO 126:POKE M+I,255 AND -PEEK(M+I):NEXT
160 POKE M+120,"BASIC2"
170 S=&H55:FOR I=0 TO 126:S=(S-PEEK(M+I))AND255:NEXT:PRINT "checksum="+HEX$(S)
180 POKE M+127,S
190 ' sauvegarde bootloader
200 DSKO$ 1,0,1,"":POKE &H604F,MKI$(M):EXEC &HE82A
210 'lecture code a charger
220 LOADM "bootldr.BIN",M-&H6300
230 'ecriture code
240 DSKO$ 1,0,2,"":POKE &H604F,MKI$(M):EXEC &HE82A:M=M+256
250 DSKO$ 1,0,3,"":POKE &H604F,MKI$(M):EXEC &HE82A:M=M+256
260 'copie AUTO.BIN
270 COPY "0:AUTO.BIN" TO "1:AUTO.BIN"

