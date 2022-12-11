Title:      TopOPop
Category:   Intro
Size:       1021 bytes
Features:   Colorful Sierpinski's triangle + oscilloscope + music.

Group:      PULS (http://www.pulsdemos.com)
Author(s):  Samuel Devulder
Contact:    samuel.devulder@gmail.com

Machine(s): Thomson TO7/70, TO8, TO9 (6809e @ 1Mhz) with the paddle extension.
Format:     Standard binary thomson file. Can be launched with 
                  LOADM "TOPOPOP.EXO",,r
            from the K7 or from the floppy. For convenience, AUTO.BAT is provided 
	    to ease booting the demo from the floppy or the K7. It contains the 
	    LOADM instruction and doesn't count in the production size.
Packer:     Exomizer2 by Magnus Lind

Remarks:    1) The intro runs forever (!!). You must reset the machine
               to stop it.
            2) The player is able to play 3 voices (2 instruments + noise) 
               asynchronously from a 2092hz interrupt using the 6-bit DAC 
               of the paddle extension.
            3) Music is Sega Master System's "Asterix" game song converted
               from MIDI to the player's format. http://tinyurl.com/othhx9s
               Duration: 1min 15secs
            4) Unpacked code size is about 10Kb.
            5) Source code is available on the disk.
            6) The title stands for "Top Of the Pop", because the music is
               kind of cool and could reach the top of the charts one day :p
               