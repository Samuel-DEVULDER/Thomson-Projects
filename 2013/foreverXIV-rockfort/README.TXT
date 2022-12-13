Title:      Rock Fort
Category:   Intro
Size:       1008 bytes
Features:   3-colors 3D-starfield + scroller + raster-colors + music.

Group:      PULS (http://www.pulsdemos.com)
Author(s):  Samuel Devulder (orig. idea, code) & Préhisto (optim.)
Contact:    samuel.devulder@gmail.com

Machine(s): Thomson TO7/70, TO8, TO9 (6809e @ 1Mhz) without extensions.
Format:     Standard binary thomson file. Can be launched with 
                  LOADM "",,r
            from the K7 and
	          LOADM "ROCKFORT",,r
            from the floppy. For the ease, AUTO.BAT is provided on the floppy.
 	    It contains the LOADM instruction and doesn't count in the 
	    production size.
Packer:     Exomizer2 (1603b down to 824b plus 184b decruncher)

Remarks:    1) Press any key to go back to the boot menu.
            2) Music is rare on the Thomson machines as they don't contain 
               music chip. The base plateform actually only contains an single 
	       buzzer. This production features a very compact and full CPU 
	       + timer score player.
	    3) The scroller take about 10secs to do a full (rock&)roll over 
	       the 256-pixels wide zone. This means that the production runs 
	       at about 25fps.
	    4) Music is AC/DC's "back in black" converted from MIDI to internal
	       score.
            5) The title is a pun. "rock fort" can be translated as hard rock 
	       which refers to AC/DC. It also relates to Roquefort, a well 
	       known French cheese.
	    6) For sure ELVIS LIVES! We've even got 4 copies of him in the 
	       corners of the screen ;-)
	    7) I would go further and say ELVIS LIVES FOREVER (14).
            

