
10 LOCATE 0,0,0:CONSOLE,,1:CLS
20 PRINT"  _   _  _   _ __ __   ___  ___  _  ___ ";
30 PRINT" | |_| || \ | |\ V /  (_  )|   || |(_  |";
40 PRINT" |  _  || |\| | | |    /2/ | O ||1| _3 |";
50 PRINT" |_| |_||_| \_| |_|   (___)|___||_|(___|";
60 PRINT
70 PRINT"       http://www.pulsdemos.com         ";
80 PRINT
90 PRINT"    Le Groupe PULS souhaite une bonne et";
100 PRINT"heureuse annBee  2013  Aa tous les THOMSON";
110 PRINT"de la planAete, ainsi qu'Aa  leurs heureux";
120 PRINT"propriBetaires."
130 PRINT
140 PRINT"    Cette dBemo fonctionne sur toutes les";
150 PRINT"machines TO  pourvus  d'un lecteur de D7";
160 PRINT"et d'une  extension  mBemoire (du TO7+16k";
170 PRINT"jusqu'au TO9+)"
180 PRINT
190 PRINT"    Des flocons  tombent et s'accumulent";
200 PRINT"sur le sol pendant que de la musique est";
210 PRINT"jouBee en tache de fond par le buzzer."
220 PRINT
230 PRINT"    L'appui  sur les touches CTRL-C fait";
240 PRINT"revenir au menu,  et  les autres touches";
250 PRINT"nettoient la neige."
260 PRINT"                                .../...";
270 BEEP:A$=INPUT$(1)
280 PRINT"    Le  code  source  est prBesent sur la";
290 PRINT"diskette  et  contient  une routine pour";
300 PRINT"jouer de  la  musique en tache  de fond.";
310 PRINT"Les morceaux  de  musique  viennent pour";
320 PRINT"une part de conversions  MIDI et d'autre";
330 PRINT"part de conversion des morceaux utilisBes";
340 PRINT"par le Floppy Drive Music project:"
350 PRINT
360 PRINT"    http://tinyurl.com/b9wcpnr (*)"
370 PRINT
380 PRINT"Les morceaux de musiques sont:"
400 PRINT"     1) Mon beau sapin (*)"
410 PRINT"     2) Vive le vent (*)"
420 PRINT"     3) Here Comes Santa Claus"
430 PRINT"     4) Super Mario Theme (*)"
440 PRINT"     5) Tetris (*)"
450 PRINT"     6) Zelda - Overworld Theme (*)"
460 PRINT"     7) Zombie Nation (*)"
470 PRINT"     8) Nyan Cat (*)"
480 PRINT"     9) Rick Dangerous"
490 PRINT"    10) Cauldron I"
500 PRINT"    11) Bubble Bobble"
510 PRINT"    12) James Bond (*)"
520 PRINT"    13) Starwars - Marche Impriale (*)"
530 PRINT"    14) Alphaville - Big In Japan";
540 BEEP:A$=INPUT$(1)
550 A=PEEK(&hFFFE)*256+PEEK(&hFFFF)
560 exec A
