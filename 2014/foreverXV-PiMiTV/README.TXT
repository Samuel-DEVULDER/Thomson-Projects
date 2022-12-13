Title:      PiMiTV
Category:   Intro
Size:       1024 bytes
Features:   Kefrens-Bar + music.

Group:      PULS (http://www.pulsdemos.com)
Author(s):  Samuel Devulder
Contact:    samuel.devulder@gmail.com

Machine(s): Thomson TO7/70, TO8, TO9 (6809e @ 1Mhz) with the paddle extension.
Format:     Standard binary thomson file. Can be launched with 
                  LOADM "PiMiTV.EXO",,r
            from the K7 or from the floppy. For convenience, AUTO.BAT is provided 
	    to ease booting the demo from the floppy or the K7. It contains the 
	    LOADM instruction and doesn't count in the production size.
Packer:     Exomizer2 by Magnus Lind

Remarks:    1) The intro runs forever (!!). You must reset the machine
               to stop it.
            2) The player is able to play 3 voices (2 instruments + noise) 
               asynchronously from a 2092hz interrupt using the 6-bit DAC 
               of the paddle extension.
            3) Music is Amiga's "F/A-18 Interceptor" main theme converted
               from MIDI to the player's format.
               Duration: 2mins 37secs
               URL:      http://tinyurl.com/k8uu9sv
            4) Unpacked code size is about 14Kb.
            5) Source code is available on the disk.
            6) The title is an acronym. PiMiTV stands for Pierre de 
               Coubertin's idea: Participation Is More Important Than Victory,
               which pretty well relates this intro to the olympic theme of 
               Forever XV :p
               