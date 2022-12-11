Title:      When Rings Become Pumpkins
Category:   Intro
Size:       1022 bytes
Features:   Bouncing Olympic rings dancing on Cauldron-2 music.

Group:      PULS (http://www.pulsdemos.com)
Author(s):  Samuel Devulder
Contact:    samuel.devulder@gmail.com

Machine(s): Thomson TO7/70, TO8, TO9 (6809e @ 1Mhz) with the paddle extension.
Format:     Standard binary thomson file. Can be launched with 
                  LOADM "WRBP.EXO",,r
            from the K7 or from the floppy. For convenience, AUTO.BAT is provided 
	    to ease booting the demo from the floppy or the K7. It contains the 
	    LOADM instruction and doesn't count in the production size.
Packer:     Exomizer2 by Magnus Lind

Remarks:    1) The intro runs forever (!!). You must reset the machine
               to stop it.
            2) The player is able to play 3 voices (2 instruments + noise) 
               asynchronously from a 2092hz interrupt using the 6-bit DAC 
               of the paddle extension.
            3) Music is C64's "Cauldron 2" main theme converted from MIDI 
               to the player's format. http://tinyurl.com/paap3wj
               Duration: 1min 32secs
            4) Unpacked code size is about 27Kb.
            5) Source code is available on the disk.
