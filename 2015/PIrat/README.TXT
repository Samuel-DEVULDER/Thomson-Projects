These programs compute PI digits using the SPIGOT algorithm
on Thomson machines (6809@1Mhz).

The idea to implement that algorithm on 6809 comes from
Serzhsoft and its 119 bytes version for the ZX Spectrum:
         http://www.pouet.net/prod.php?which=66568

This version displays more digits than the ZX version suggesting
that PI is indeed a rationnal number (surprise!).

The initial implementation was proposed as a "what is it?" quizz:
     http://www.logicielsmoto.com/phpBB/viewtopic.php?p=4465
but it didn't fit into the 128 bytes challenge of the ZX version.

There are two programs:
- sPIgot.BIN which occupies 128 bytes of memory. It only runs
  on the "TO" machines and doesn't return to the system. It is
  extremmely slow dropping one new digit around every minute.
  Expect more than 10 hours for the whole program to complete,
  this is indeed one of the slowest implementation of the spigot
  algorithm for the 6809, but it fits the 128 bytes challenge :D

- PIrat.BIN which is 253 bytes but is more user- and system-
  friendly. It can run on any thomson machines (TO or MO versions).
  It is also much much faster (about 60 times), displaying one new
  digit every second. This is the recommanded version to test first.

Look at the provided source-code for more explanations.

Author: Samuel DEVULDER (aka __sam__)
Group:  PULS (http://www.pulsdemos.com)

