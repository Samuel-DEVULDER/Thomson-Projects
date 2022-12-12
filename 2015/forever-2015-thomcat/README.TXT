Title:      THOM-CAT
Category:   Intro
Size:       995 bytes on disk (985 in memory).
Features:   - multi-machine (TO/MO)
            - animation (inspired by http://goo.gl/dVT4j8)
            - sound effect
            - font smoother
            - two speed scroller.

Group:      PULS (http://www.pulsdemos.com)
Author:     Samuel Devulder (aka __sam__, sam)
Contact:    samuel.devulder@gmail.com

Machine(s): Thomson MO5, MO6, TO7, TO7/70, TO8, TO9, TO9+
            (6809e @ 1Mhz) without extensions.

Format:     Standard binary thomson file, TO/MO K7 files and and WAV files.

            Can be launched with
                  LOADM "THOM-CAT",,R
            from the tape or the floppy on both TO/MO machines.

            For the ease, AUTO.BAT is provided on the floppy.

            It contains the LOADM instruction and doesn't count in the
            production size.

Packer:     None :) The cat animation and the background picture are encoded
            in an efficient ad-hoc format.

Remarks:    1) Press any key to go back to the boot menu.
            2) Thanks to Muybridge for letting me use his cat as a model.
               http://en.wikipedia.org/wiki/Eadweard_Muybridge
            3) The animation is based on the very same principle as the
               one used by brusspup on http://goo.gl/dVT4j8.
            4) The TO and MO architectures are incompatible with respect to
               both ROM API and some HW registers. Nonetheless, this intro
               is able to cope with both architectures. This is possibly a
               first-time in the (very short) history of intros on Thomson's 
               machines.
            5) The source code is provided in the archive file.	
            6) The intro has been tested on the TO8D and MO6 real hardware.
               Tests for other machines has been performed using emulators.
