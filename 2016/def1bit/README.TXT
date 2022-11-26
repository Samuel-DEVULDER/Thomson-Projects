Title:      DEF1BIT (Defender of the 1 bit)
Category:   Intro
Size:       1024 bytes
Rank:       4th
Party:      Forever-Party o17 - Horna Suca 2016

Features:   A variation of the party-theme image is displayed 
            using teletel characters while a small music is played. 
            
            The music is the theme of "Defender of the Crown" and
            features a very small 3 voices player that uses the 1 bit 
            buzzer of the Thomson machines.
            
Group:      PULS (http://www.pulsdemos.com)
Author:     __sam__ (Samuel DEVULDER)

Machine(s): Thomson TO7/70, TO8, TO9, TO9+ (6809e @ 1Mhz) without 
            any expansion.

Format:     Standard binary thomson file. Can be launched with 
                  LOADM "def1bit.EXO",,r
            from the K7. For convenience, a special bootblock is 
            present on the floppy to load a copy of this intro
            named "AUTO.BIN". It works on any machine having a 
            floppy controller, even with BASIC 1.
            
Packer:     Exomizer2 by Magnus Lind

Remarks:    1) You can quit the intro by pressing any key (provided your
               emulator properly emulates the undocumented opcode $3E)
            2) When uncompressed the intro uses 3.2kb of ram. 
            3) The code uses less than 128byte. The rest is used by the
               data (1.5kb image and 1.5kb music).
            4) Source code is available on the disk.
