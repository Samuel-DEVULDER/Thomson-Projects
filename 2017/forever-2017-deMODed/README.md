(image)[img/menu.gif]
# Description
|------------|---------------------------------------|
|------------|---------------------------------------|
|_Title_     | TO8 deMODed?                          |
|*Category*  | Demo (other 8 bits)                   |
|*Rank*      | 1st                                   |
|*Party*     | Forever-Party 2017 - Horna Suca       |
|*Features*  | Over one hour of a technical demonstration of a new sound routine.|
|*Group*     | PULS (http://www.pulsdemos.com)       |
|*Author(s)* | Samuel Devulder (conception, code),
               Prehisto (bootloader + trackloader),
               Exocet (menu & puls images)           |
|*Machine(s)*| Thomson TO8, TO8D, TO9+ (6809e @ 1Mhz)|
|*Format*    | Single standard Thomson disk in various emulator formats (SAP, FD).|
|------------|---------------------------------------|
# HISTORY

Last year PULS showed that with huge effort, the Thomson machines
that are usually silent, can produce sound and even play a karaoke,
entertaining (some of) Forever's visitors ;) Erh, well, saying
sound in that context is kind of misleading since it was only
producing square waves, eg. BEEPS. Yes the Thomson can BEEP, and
it BEEPs quite well indeed :)

Though the Thomson machine still lack a proper sound chip, the
original designers provided the joystick expansion with a 6 bits
DAC. It was rarely been used because it typically requires loading
a full disk of data into RAM and then send them back to the DAC at
a fixed pace by a CPU loop. And damn, this is slow. Loading from
the floppy takes ages for only a few couple of minutes of sound.
That was the state of the art for the Thomson's for a long time.

This year PULS realized that it is possible to go one step further
by using the playback routine designed there:
    http://www.logicielsmoto.com/phpBB/viewtopic.php?f=3&t=549
    (in French, sorry guys :( Use google translate ;) )

That routine mixes 4 independent 4-bits channels, each one with
its own frequency, volume and instrument, and sends the result to
the DAC in 200 cycles. This means that were are more or less
emulating the work of the Amiga audio chip, Denise, except that
it is done with 4bits per sample at 5khz max instead of 8bits at
28khz max. Well, that difference may seem too huge to provide any
decent audio quality, but the tests prove that it is not! (Notice
that 5khz is more than the bandwidth used in telephony).

Emulating the amiga sound chip is a nice technical idea, but since
this eats all of the cpu time, one cannot do anything interesting
with it like playing a MOD, can one? Well, quite to our surprise,
it appeared that one can interrupt the playback routine from time
to time and modify the parameters (volume, frequency) without
noticeable quality prejudice. This allows playing MODs on an 8 bit
as well!!!

So this year, for the first time on the Thomson machines PULS
introduces you a demo disk containing more that 15 famous tunes
of the 16 bit world :-)

        ==>>>> ENJOY OVER ONE HOUR OF MUSIC! <<<<<==

# FOREVER THEME?

Okay, this is all very well. But one might ask how does this
production fit into this year theme? Have a close look at
the credits, and more precisely to the first tune author. See?
Got it? Yes!!!!!!
 _________   ______   _____       _________   ______   _    _
/  _   _  \ /  __  \ |  __ \     /  _   _  \ /  __  \ | |  | |
| | | | | | | |__| | | |  \ \    | | | | | | | |__| | | |__| |
| | | | | | |  __  | | |  | |    | | | | | | |  __  |  > __ <
| | | | | | | |  | | | |__/ /    | | | | | | | |  | | | |  | |
|_| |_| |_| |_|  |_| |_____/     |_| |_| |_| |_|  |_| |_|  |_|

Mad Max!!!! That's it :) :) :)

# CREDITS

Here are the credits for the MODs and GFX that we used in this
production. PULS sends all its greetings to them!

Tune #1
    MOD: Hallucinations
         by Mad Max
         of Katharsis
    GFX: Python, excerpt of "Hallucinations and Dreams -
         Preview (Trackmo)"
    WWW: http://janeway.exotica.org.uk/release.php?id=8625

Tune #2
    MOD: Banana split
         by Dizzy
         of CNCD
    GFX: Excerpt of "Racer 2" by Dune (Templeton, Calimero)
    WWW: https://demozoo.org/music/5947/

Tune #3
    MOD: Crack the eggshell
         by Jester
         of Sanity
    GFX: Havok, excerpt of "BoggleDop(demo)"
    WWW: http://janeway.exotica.org.uk/release.php?id=47573

Tune #4
    MOD: Lightchamber
         by Deelite
         of Balance
    GFX: Pixie, excerpt of "Eurochart 28 (Diskmagazine)"
         by Depth
    WWW: http://janeway.exotica.org.uk/release.php?id=747

Tune #5
    MOD: Cream of the earth
         by Romeo Knight
         of R.S.I.
    GFX: Kent Valden (https://www.youtube.com/watch?v=88ZqSl6Ud8k)
    WWW: http://janeway.exotica.org.uk/release.php?id=32233

Tune #6
    MOD: Adrenaline
         by Blaizer
         of Digital Illusions
    GFX: Excerpt of the game "Pinball Fantasies"
         by Digital Illusions
    WWW: https://www.youtube.com/watch?v=nXrwgy-uFg8

Tune #7 & #8
    MOD: Hardwired2 & Global trash 3 v2
         by Jesper Kyd
         of The Silents
    GFX: Zycho/Crionics, excerpts of the demo Hardwired
         by Crionics & The Silents
    WWW: http://janeway.exotica.org.uk/release.php?id=504

Tune #9
    MOD: Condom Corruption
         by Travolta
         of Spaceballs
    GFX: TMB designs, excerpt of the demo "State of the art"
         by Spaceballs
    WWW: https://www.scenemusic.net/demovibes/song/7169/

Tune #10
    MOD: Testlast
         by Travolta
         of Spaceballs
    GFX: TMB designs, excerpt of the demo "9 fingers"
         by Spaceballs
    WWW: http://janeway.exotica.org.uk/release.php?id=1060

Tune #11
    MOD: Livin' insanity
         by Moby
         of Sanity
    GFX: RA, excerpt of the Arte demo by Sanity
    WWW: http://janeway.exotica.org.uk/release.php?id=279

Tune #12
    MOD: Elekfunk!
         by Moby
         of Sanity
    GFX: RA, excerpt of the Arte demo by Sanity
    WWW: http://janeway.exotica.org.uk/release.php?id=279

Tune #13
    MOD: Klisje paa klisje
         by Walkman
         of Cryptoburners
    GFX: Bugbear, excerpt of "The Hunt For 7th October"
         by Cryptoburners
    WWW: https://www.scenemusic.net/demovibes/song/8478/

Tune #14
    MOD: A way to freedom
         by LizardKing
         of Razor 1911
    GFX: Electron, Issue 2 of "Oepir Risti"
    WWW: http://janeway.exotica.org.uk/release.php?id=49664

Tune #15
    MOD: Blur
         by Oxide
         of Sonik Clique
    GFX: Excerpt of https://demozoo.org/productions/7484/
    WWW: https://demozoo.org/music/141810/

Tune for Menu
    MOD: supershort
         by Chrono
         of S!P
    WWW: ftp://ftp.modland.com/pub/favourites/Protracker/Chrono/

# REMARKS
1) If you intend to listen the disk on an emulator, please
   choose one that respects the disk timings, or the waiting
   delays won't be good.

   One such emulator is TEO 1.8.3:
        https://sourceforge.net/projects/teoemulator/

   On other emulators, there might be an option to enable
   accurate disk speed. Read the manual ;)

2) During playback you can mute/unmute all the channels
   by pressing the '0' key. If you happen to hear no sound,
   this is probably because you accidently pressed the '0'
   key. To unmute, press '0' again.

   You can also mute/unmute a specific channel by pressing
   on the 1-4 key.

   If you press ENTER, then the menu will automatically
   choose the next tune.

   If you press SPACE, the tune stops and you get back to
   the menu.

3) In the menu, if you press the '=' key, the same tune is
   played again, and ENTER plays the next tune.

4) Special guest: Pulkomandy in the first two pictures.
   Big thank to him!
