#Sindots in 176 bytes.

Idea from: https://www.pouet.net/prod.php?which=65599

Forum: http://www.logicielsmoto.com/phpBB/viewtopic.php?f=3&t=524&hilit=quizz#p4405

Binary:
```
****************************************
* debut  : $8000
* fin    : $80AF
* taille : 176
****************************************

        org     $8000

init    fcb     $CE,$80,$A1,$37,$38
        fcb     $E6,$C0,$BD,$E8,$03
        fcb     $26,$F9,$E7,$01,$E7
        fcb     $84,$E7,$84,$CB,$10
        fcb     $26,$F8,$56,$E7,$A0
        fcb     $26,$FB,$3D,$A7,$A0
        fcb     $40,$A7,$A8,$7F,$CC
        fcb     $FF,$00,$C3,$FE,$02
        fcb     $DD,$23,$26,$EF,$8D
        fcb     $13,$80,$08,$CB,$08
        fcb     $8D,$0D,$8B,$09,$C0
        fcb     $09,$BD,$E8,$09,$24
        fcb     $EF,$6E,$9F,$FF,$FE
        fcb     $34,$06,$DD,$92,$20
        fcb     $07,$CC,$00,$00,$8B
        fcb     $07,$C0,$03,$DD,$48
        fcb     $A6,$A6,$AB,$A5,$8B
        fcb     $64,$2D,$39,$81,$C8
        fcb     $24,$35,$C6,$28,$3D
        fcb     $8B,$40,$1F,$01,$DC
        fcb     $92,$A6,$A6,$AB,$A5
        fcb     $1F,$89,$57,$57,$57
        fcb     $CB,$14,$3A,$84,$07
        fcb     $A6,$C6,$C6,$00,$C4
        fcb     $FF,$26,$05,$43,$A4
        fcb     $84,$20,$0F,$54,$C4
        fcb     $78,$C8,$C0,$7A,$E7
        fcb     $C3,$E7,$84,$7C,$E7
        fcb     $C3,$AA,$84,$A7,$84
        fcb     $CC,$00,$00,$5A,$80
        fcb     $07,$DD,$92,$0C,$76
        fcb     $26,$AA,$03,$78,$35
        fcb     $86,$80,$E7,$DA,$80
        fcb     $B0,$1B,$50,$1B,$60
        fcb     $14,$0C,$51,$42,$3F
        fcb     $00

        end     init
```

Result:
![](https://content.pouet.net/files/screenshots/00065/00065599.png)