globals [ nbTas ]
patches-own
[
  quelTas                                 
]


;;======================================================================
;;
;; On fixe le nombre d'élément à trier (nbOjets par couleurs)
;; On essaye d'avoir une répartition homogène en fonction de la taille 
;;
;;======================================================================

to initPatches
  ask patches [
    if ( random-float (( world-width * world-height) / (nbObjetsParCouleur * couleurs)) < 1)
    [set pcolor ( random couleurs ) * 20 + red 
     set quelTas nobody  
    ]
  ]
end


;;======================================================================
;;
;; Pour être en mesure de gérer la grille entre -max-pxcor et +max-pxcor
;; et -max-pycor  et +max-pycor
;;
;;======================================================================

to-report unOuMoinsUn
  ifelse (random 2 = 0)
  [report -1]
  [report 1]
end


;;======================================================================
;;
;; On crée les tortues qui deviennent des fourmis
;;
;;======================================================================

  
to setup 
  ca                                                      ; On fait le ménage le monde, les variables ....
  initPatches                                             ; On initialise le monde avec les objets/larves à trier
  crt fourmis                                             ; Les tortues sont des fourmis !!!
  ask turtles                                          
  [ set shape "ant"
    set color white                                       ; fourmi blanche = main vide 
    ht                                                    ; On affiche les fourmis
    setxy random max-pxcor * unOuMoinsUn                  ; La grille n'est pas un tore 
          random max-pycor * unOuMoinsUn
  ]
  if Compte? [ compteTas ]
  reset-ticks
end




;;======================================================================
;;
;; Les patches contiennent les larves (couleurs)
;; À chaque pas de temps les fourmis se déplacent sur une case adjacente ;
;; Si une fourmi arrive sur une case de couleur elle peut "l'emporter" ou la laisser
;;    Si la densité locale de la couleur est faible, elle a tendance à l'emporter 
;;    Sinon elle a tendance à la laisser.    
;;
;; Si une fourmi transporte une couleur elle peut la déposer ou la garder
;;    Si la densité locale de la couleur est forte, elle a tendance à la déposer ;
;;    Si elle est faible, elle a tendance à la garder.    
;;
;;======================================================================

to couvain
  ask turtles [ 
  ifelse cachée? [ ht ] [ st ]  
  ifelse ( color = white )                                ; La fourmi a les bras vide 
    [ if ( pcolor > black )                               ; Le patch est occupé
        [ 
          if ( nbLarvesIdentiques pcolor 1 <= (random 6))  ; Ce n'est pas un tas dense 
          [ set color pcolor                               ; La fourmi prend la larve
            set pcolor black                              ; Le patch n'est plus occupé
          ] 
        ] 
    ] 
    [ if ( pcolor = black )                                   ; La fourmi porte quelque chose elle regarde si le patch est vide 
      [ 
        if ((nbLarvesIdentiques color 1) > (1 + random 4)) 
        [ 
          set pcolor color                                ; Elle dépose
          set color white                                 ; Elle a les bras vides          
        ] 
      ] 
    ] 
  set heading heading + random 45 - random 45   
  fd 1 
  ]
  if Compte? [ compteTas ]
  tick
end


to-report nbLarvesIdentiques [col dist]
  let ligne (- dist)
  let colonne (- dist)
  let nb 0
  repeat (2 * dist) + 1
  [
    repeat (2 * dist) + 1
    [
      if (patch-at ligne colonne != nobody)
      [
        if ([pcolor] of (patch-at ligne colonne) = col)
        [ set nb nb + 1 ]
      ]
      set colonne colonne + 1   
    ]
    set colonne (- dist)
    set ligne ligne + 1
  ]
  report nb - 1
end 

to compteTas
  ask patches [ set quelTas nobody ]
  set nbTas 0
    loop [
    ;; On choisit un patch et on regarde le voisinage
    let larve one-of patches with [quelTas = nobody and pcolor != black]
    if larve = nobody
    [ stop ] ;; On stoppe la boucle
    set nbTas nbTas + 1
    ask larve
    [ set quelTas self
      rechercherLesAutres ]
  ]
end 

to rechercherLesAutres  
  ask neighbors with [(quelTas = nobody) and
    (pcolor = [pcolor] of myself)]
  [ set quelTas [quelTas] of myself
    rechercherLesAutres ]
end



 
@#$#@#$#@
GRAPHICS-WINDOW
10
40
525
576
50
50
5.0
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
30.0

SLIDER
535
105
705
138
NbobjetsParCouleur
NbobjetsParCouleur
0
5000
420
10
1
NIL
HORIZONTAL

SLIDER
535
65
707
98
couleurs
couleurs
0
100
4
1
1
NIL
HORIZONTAL

SLIDER
535
25
707
58
fourmis
fourmis
0
100
100
1
1
NIL
HORIZONTAL

BUTTON
10
10
95
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
95
10
157
43
go
couvain
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
545
190
662
223
cachée?
cachée?
0
1
-1000

MONITOR
550
285
607
330
nbTas
nbTas
17
1
11

TEXTBOX
545
170
705
196
Les fourmis sont-elles visibles ?
10
0.0
1

TEXTBOX
550
230
700
248
NIL
10
0.0
1

TEXTBOX
545
240
695
276
On compte le nombre de tas ?\n(ralenti fortement la simulation)
10
0.0
1

SWITCH
605
285
710
318
Compte?
Compte?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

Les fourmis ont la capacité collective de trier des objets. Cette particularité a retenu depuis longtemps l'attention des naturalistes en particulier en observant des "cimetières" de fourmis.
<center> 
  <img src="./6911549446_bd76ee3ac7_z.jpg" alt="Cimetière de fourmi" /> 
  Cadavres de fourmis, source : [1]
</center>

Cette aptitude suivant les espèces s'entend également au tri d'éléments du couvain comme les oeufs, les larves et les nymphes. 

Lorsque des cadavres sont déposés dans une boite de petri en quelques heures les fourmis vont les regrouper en tas comme le montre [2].

<center> 
  <img src="./ExperienceTheraulaz_scale0_5.jpg" alt="Tri collectif" /> <br/>
  Tri collectif. Source : Theraulaz G et al. PNAS 2002;99:9645-9649,  [2].
</center>

Ce programme NetLogo s'intéresse donc au tri collectif et tente de modéliser le comportement des fourmis.


## HOW IT WORKS
Cela fonctionne simplement. Chaque fourmi est capable de prendre un cadavre, de se déplacer puis de le déposer. Le comportement d'une fourmi est probabiliste, ainsi plus un tas est petit, plus la fourmi a de chance de prendre un cadavre et plus un tas est important plus elle a de chance de déposer la charge qu'elle transporte éventuellement près de ce tas. Ses déplacements sont aléatoires dans l'environnement. 

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

Si le résultat est bien collectif peut-on réellement parler dans ce cas d'intelligence collective ou en essaim ? Chez les fourmis sans doute, mais algorithmiquement c'est plus discutable, en effet on pourra constater que l'on obtient un résultat identique si on utilise une unique fourmi. Il n'y a pas d'auto-organisation en particulier car il y a absence de retroaction négative entre autre.
 
(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

[1] Luca Biada,  https://www.flickr.com/photos/pedroscreamerovsky/6911549446/in/photostream/, 8 avril 2012, licence CC2. 

[2] G. Theraulaz, E Bonabeau, S. C. Nicolis, R. V. Solé, V. Fourcassié, S. Blanco, R. Fournier, _et al_. _Spatial Patterns in Ant Colonies_. Proceedings of the National Academy of Sciences 99, nᵒ 15 : pages 9645‑49, 23 juillet 2002. doi:10.1073/pnas.152302199.

[3] H. VD. Parunak.  _“Go to the Ant”: Engineering Principles from Natural Multi-Agent Systems_. Annals of Operations Research 75, nᵒ 0 pages 69‑101, 1997. doi:10.1023/A:1018980001403.

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

ant 2
true
0
Polygon -7500403 true true 150 19 120 30 120 45 130 66 144 81 127 96 129 113 144 134 136 185 121 195 114 217 120 255 135 270 165 270 180 255 188 218 181 195 165 184 157 134 170 115 173 95 156 81 171 66 181 42 180 30
Polygon -7500403 true true 150 167 159 185 190 182 225 212 255 257 240 212 200 170 154 172
Polygon -7500403 true true 161 167 201 150 237 149 281 182 245 140 202 137 158 154
Polygon -7500403 true true 155 135 185 120 230 105 275 75 233 115 201 124 155 150
Line -7500403 true 120 36 75 45
Line -7500403 true 75 45 90 15
Line -7500403 true 180 35 225 45
Line -7500403 true 225 45 210 15
Polygon -7500403 true true 145 135 115 120 70 105 25 75 67 115 99 124 145 150
Polygon -7500403 true true 139 167 99 150 63 149 19 182 55 140 98 137 142 154
Polygon -7500403 true true 150 167 141 185 110 182 75 212 45 257 60 212 100 170 146 172

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
