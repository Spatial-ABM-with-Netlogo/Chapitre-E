globals [
  max-id                                                  ; sommet d'arrivée 
  min-id                                                  ; sommet de départ
]

breed [noeuds noeud]                                      ; Pour construire le graphe
breed [fourmis fourmi]                                    ; Les fourmis qui cherchent le chemin
breed [chemins plus-court]                                ; Pour construire le chemin le plus court
                                                          ; trouvé par les fourmis
noeuds-own [noeud-id]                                     ; Numéro du sommet
fourmis-own [
  de-a vers-b                                             ; De quel sommet vers quel sommet 
  itinéraire                                              ; Le chemin emprunté
  delai                                                   ; Délai d'attente avant de partir du nid
  aller?                                                  ; true -> nid vers source de nourriture
]

links-own [phéromone]                                     ; Quantité de phéromone déposé sur l'arc

  ;;----------------------------------------------------------------------------------------
  ;; Les traditionnelles fonctions setup et go
  ;; 
to setup
  ca
  setup-graphe
  setup-fourmis
  create-chemins 1 
  reset-ticks
end

to setup-graphe
  set max-id 1
  set min-id 1
  set-default-shape noeuds "circle"
  lecture-graphe
end

to setup-fourmis
  create-fourmis nb-fourmis [
    set shape "ant"
    set color red
    set aller? true
    set delai random nb-fourmis
    set de-a get-noeud min-id
    set vers-b choix-destination
    move-to de-a
    face vers-b
  ]
end

to go
  ask fourmis with [delai <= ticks]                      ; Les fourmis ne partent pas toutes en même temps 
  [
    ifelse cacher-les-fourmis [ ht ] [ st ]                   
    ifelse distance vers-b = 0                           ; La fourmi est arrivée sur un sommet
    [
      if not aller? [                                      ; Elle est entrain de revenir au nid,
        ask link [who] of de-a [who] of vers-b             ; elle dépose donc des phéromones sur les arcs traversés.
        [ 
          ifelse biais
          [ set phéromone (phéromone + dépot / link-length ) ]; La quantité de phéromone est inversement proportionnelle à la longueur de l'arc
          [ set phéromone (phéromone + dépot ) ]
          set label phéromone
        ]
      ]
      set de-a vers-b                                      ; Il faut choisir la nouvelle destination
      set vers-b choix-destination
      face vers-b
    ]
    [                                                    ; La fourmi est sur un arc
      ifelse distance vers-b <= 2                          ; Elle est proche du sommet ?  
      [ move-to vers-b ]                                     ; Oui, elle se rend dirrectement sur le soomet
      [fd 1 + random-float 1                                 ; Non, elle avance 
      ]  
    ]
  ]
  ask links [ set thickness 0 ]  
  if afficher-chemin [plus-court-chemin]
  evaporation
  tick
end
   ;;----------------------------------------------------------------------------------------

   ;;----------------------------------------------------------------------------------------
   ;; Le graphe
   ;; 
to lecture-graphe
   ;; Le graphe est stocké dans un fichier texte. Les sommets sont une espèce de tortue. Attention l'identificateur
   ;; du sommet ne correspond pas au numéro de la tortue (who). Les noeuds sont numérotés à partir de 1. Le nid est
   ;; en 1 et le sommet ayant le plus identifiant correspond à la source de nourriture.
   ;; La structure est la suivante (ex) : 
   ;; 3                                      Nombre de sommets
   ;; 1 0 -20                                id xcor ycor
   ;; 2 0 -15
   ;; 4 18 -8                   
   ;; 1 2                                    arc entre le noeud 1 et 2
   ;; 1 4
   ;;
  let fichier "" 
  ifelse quel-graphe = "binary bridge" 
  [ set fichier "bridge.txt" ]                              ; Exemple par défaut
  [ set fichier user-file ]                                 
  ifelse ( file-exists? fichier )
  [
    file-open fichier
    let nbVertices file-read
    repeat nbVertices [
      create-noeuds 1 [                                     ; Création des sommets
      set color blue
      set size 3
      set noeud-id file-read
      if noeud-id > max-id
      [ set max-id noeud-id ]
      if noeud-id < min-id
      [ set min-id noeud-id ]
      setxy file-read file-read
      ]
    ] 
    while [not file-at-end?]                                  ; Création des arcs 
    [
      let items read-from-string (word "[" file-read-line "]")
      ask get-noeud (item 0 items)
      [            
        create-link-with get-noeud (item 1 items) 
        [
          set phéromone 0.1                                   ; Pour éviter tout risque de / 0
          set thickness 0
        ]
      ]
    ]
    file-close
  ]
  [ user-message "Le fichier est introuvable" ]
end

to modifier-graphe
  ;; Possibilité de modifier la taille des arcs interactivement durant la simulation
  if mouse-down? [
    let candidat min-one-of noeuds [distancexy mouse-xcor mouse-ycor]
    if [distancexy mouse-xcor mouse-ycor] of candidat < 1 [
      let selectedfourmis fourmis with [de-a = candidat or vers-b = candidat]
      watch candidat
      while [mouse-down?] [
        display
        ask subject [ setxy mouse-xcor mouse-ycor ]
        ask selectedfourmis [setxy mouse-xcor mouse-ycor face vers-b]
      ]
      reset-perspective 
    ]
  ]
end
   ;;----------------------------------------------------------------------------------------

   ;;----------------------------------------------------------------------------------------
   ;; Traitement du graphe
   ;; 
to-report choix-destination
  ;; Détermine la nouvelle destination d'une fourmi, connaissant le noeud de départ (de-a).
  let id-de-a [noeud-id] of de-a
                                                             ; La fourmi a t-elle atteint le nid ou la source ?
  if id-de-a = max-id [ set aller? false]                      ; Source => retour
  if id-de-a = min-id                                          ; Nid => aller
  [ 
    set aller? true
    set itinéraire []                                          ; Nouveau chemin
  ]
  let ou-on-va 0                                             ; On cherche maintenant à déterminer la destination
  ifelse aller?
  [                                                          ; Nid -> source, on utilise les phéromones et on construit les probas
    let quantité-phéromone 0
    let x de-a
    let proba []
    ask links with [end1 = x] [                              ; On somme la quantité de phéromone de tous les arcs incidents à a (a vers un autre sommet)  
      set quantité-phéromone quantité-phéromone + phéromone  
      set proba lput (list phéromone self) proba             ; On construit une liste du type ((quantité-1 (link sommet-i sommet-j)) ..... (quantité-n (link sommet-k sommet-l))
                                                             ; Supposons a -> b 10 ; a -> c 30 ; a -> d 20  ((10 (link a b) (30 (link a c) (20 (link a d)) 
    ]
    set proba sort-by [first ?1 <= first ?2] proba           ; ((10 (link a b) (20 (link a d) (30 (link a c)) 
    let probabilités []
    let cumul 0
    foreach proba 
    [
      let p first ?
      let lien last ?
      set probabilités lput (list ( (p + cumul) / quantité-phéromone) lien) probabilités
      set cumul cumul + p
    ]                                                        ; ((10/60 (link a b) (30/60 (link a d)) ((60/60 (link a c))
    let rand-num random-float 1.                             ; rand-num 0.4 p.e
    set ou-on-va [end2] of last first filter [first ? > rand-num] probabilités ; ou-on-va est donc d
    set itinéraire fput link [who] of de-a [who] of ou-on-va itinéraire ; on stocke l'arc dans le chemin de la fourmi
  ]
  [                                                           ; source -> nid, on dépile l'itinéraire
    set ou-on-va [end1] of first itinéraire                      
    set itinéraire but-first itinéraire 
  ] 
  report ou-on-va  
end

to evaporation
  ask links [
    set phéromone phéromone * (1 - (rho / 100))
  ]
end

to plus-court-chemin
  let noeud-courant get-noeud min-id
  let lien 0
  ask links [ set thickness 0]
  while [noeud-courant != get-noeud max-id]
  [
    set lien max-one-of links with [end1 = noeud-courant] [phéromone]
    ask lien [ set thickness 1]
    set noeud-courant [end2] of lien
  ] 
end

   ;;----------------------------------------------------------------------------------------
   ;; Utilitaire
   ;; 
to-report get-noeud [id]
   ;; Etabli la correspondance id du noeud du graphe id de la tortue
  report one-of noeuds with [noeud-id = id]
end
@#$#@#$#@
GRAPHICS-WINDOW
247
10
867
651
30
30
10.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
13
42
86
75
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
90
43
153
76
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
12
176
158
209
NIL
modifier-graphe
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
16
150
166
170
Stopper l'exécution et sélectionner le noeud que l'on souhaite déplacer.
8
0.0
1

SLIDER
10
259
199
292
nb-fourmis
nb-fourmis
1
1000
564
1
1
NIL
HORIZONTAL

SWITCH
11
413
200
446
cacher-les-fourmis
cacher-les-fourmis
1
1
-1000

SWITCH
11
450
199
483
afficher-chemin
afficher-chemin
0
1
-1000

SLIDER
10
312
199
345
rho
rho
0
100
10
1
1
%
HORIZONTAL

CHOOSER
10
104
153
149
quel-graphe
quel-graphe
"binary bridge" "mon graphe"
0

SWITCH
12
516
200
549
biais
biais
0
1
-1000

TEXTBOX
19
487
169
513
Prise en compte de la longueur de l'arc ?
10
0.0
1

TEXTBOX
14
298
164
316
Définit l'évaporation
10
0.0
1

SLIDER
11
351
199
384
dépot
dépot
0
100
10
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Jean-Louis Deneubourg a observé que certaines espèces de fourmi étaient capables de choisir le chemin le plus court pour aller vers une source de nourriture. Il a en particulier réalisé une expérience dite du _binary bridge_  [1-2]. montrant le phénomène.
<center> 
  <img src="./BridgeDeneubourgDiv2.png" alt="Binary bridge" /> 
  Expérience du binary bridge, source : [1]
</center>
Les fourmis trouvent **collectivement** la solution, on parle alors d'intelligence en essaim.
Ce modèle part de cette expérience pour en montrer les principes mais aussi l'intérêt pour ce qui concerne les graphes et en particulier les graphes dynamiques.

## HOW IT WORKS
L'idée est de s'inspirer du modèle naturel et de ses mécanismes et de l'utiliser au niveau algorithmique pour trouver des plus courts chemins [5].  
### Le modèle naturel
Le mécanisme repose sur un mode de communication local et indirect. En effet les fourmis sont capables de déposer dans l'environnement des molécules chimiques appelées phéromones. Ces dernières sont attractives et elles attirent donc les autres fourmis, le dépôt va alors se renforcer P.P. Grassé [3] parle de stigmergie qu'il définit comme : 
> "_la stimulation des travailleurs par l'oeuvre de ce qu'ils réalisent_".

Les fourmis commencent à explorer aléatoirement l'environnement autour du nid. Lorsqu'une ou plusieurs trouvent de la nourriture elles rentrent au nid en déposant chemin faisant des phéromones. Ces phéromones étant attractives, elles attirent les fourmis au voisinage non encore chargée de nourriture, en revenant à la colonie ces fourmis vont alors renforcer la ou les pistes de phéromone créées. Lorsque plusieurs chemins sont possibles, le plus court sera emprunté par plus de fourmis et donc de ce fait plus attractif. Les phéromones étant volatiles, elles s'évaporent et de ce fait font disparaître le marquage éventuel des plus longs chemins. Il faut noter que les fourmis tendent simplement à suivre les pistes de phéromone. Une fourmi peut quitter un chemin marqué et en découvrir un nouveau. Ce type de fluctuation permet de s'adapter à des changements au niveau de l'environnement comme l'apparition d'un obstacle.

Les fourmis font preuves d'auto-organisation qui montre quatre caractéristiques [4] :
  1. Des interactions nombreuses et multiples ;
  2. Des fluctuations ;
  3. Un mécanisme de rétroaction positive créant un phénomène d'amplification. Une piste déjà très marquée attire d'autre fourmi qui vont la renforcer.
  4. Un mécanisme de rétroaction négative qui permet une régulation. Dans le cas des phéromones il s'agit de l'évaporation. 


### Le modèle informatique

On considère tout d'abord un graphe qui est modélisé par des sommets et des arcs reliant ces derniers. Des fourmis numériques parcourent ce graphe et déposent dans l'environnement des phéromones sous la forme de valeur numériques sur les arcs. Les fourmis se déplacent dans le graphe suivant ces valeurs qui définissent des probabilités.
Supposons qu'une fourmi soit sur un noeud `A` et que de ce noeud elle puisse atteindre les noeuds `B` `C` et `D` et que sur chacun des arcs il y ait respectivement 10, 30 et 20 unités de phéromone. L'arc `A-B` a une probabilité d'être emprunté de 1/6, `A-C` de 1/2 et `A-D` de 2/3. Les fourmis construisent le chemin à l'aller entre le noeud de départ et d'arrivée et au retour marque le chemin en augmentant les phéromones sur les arcs traversés. Cela constitue la mise en oeuvre du mécanisme de rétroaction positive. La rétroaction négative consiste à faire décroître les valeurs da quantité de phéromone sur les arcs à chaque pas de temps. La fluctuation est assurée par l'aléatoire, la modification d'un chemin est alors possible et le meilleur chemin est alors découvert.


## HOW TO USE IT
**`setup`** et **`go`**, traditionnel !

**`quel-graphe`** permet de choisir le graphe sur lequel évolue les fourmis. `binary bridge` est celui par défaut, il correspond à l'expérience décrite par Deneubourg [1]. 
Un graphe est stocké dans un fichier texte. Les noeuds sont numérotés à partir de 1. Le noeud de départ est le 1 et celui d'arrivée correspondant à la source de nourriture, celui avec le plus grand identifiant. La structure du fichier sur une exemple est la suivante :
>      Nombre de sommets
>      id xcor ycor
>      sommet1 sommet2
>      .....
>      sommeti sommetj

Soit par exemple :

>      3                                      Nombre de sommets
>      1 0 -20                                id xcor ycor
>      2 0 -15
>      4 18 -8                   
>      1 2                                    arc entre le noeud 1 et 2
>      1 4
  

**`rho`** évaporation à chaque pas de temps.

**`dépot`** quantité de phéromone déposée par une fourmi sur l'arc. 

## THINGS TO NOTICE

Ce modèle est sensible aux valeurs des paramètres et des solutions fausses peuvent éventuellement être construites.

## THINGS TO TRY

* Il peut être intéressant de voir l'impact du nombre de fourmis sur la solution : qualité, vitesse d'obtention. 
* L'impact des perturbations sur le graphe.
* L'impact du biais.
* L'importance de la rétroaction négative.
* ...

Quel est le modèle minimal ?



## EXTENDING THE MODEL

* Possibilité d'ajouter, supprimer des noeuds ;
* Mettre des poids sur les arcs ;
* Proposer des stratégies de dépot ;
* Nombre de kilomètres par fourmi <;)
* ...


## REFERENCE MODELS

* File input example : http://modelingcommons.org/browse/one_model/2312
* Link walking example http://modelingcommons.org/browse/one_model/2304


## REFERENCES
[1] S. Goss, S. Aron, J.-L. Deneubourg et J.-M. Pasteels, _Self-organized shortcuts in the Argentine ant_, Naturwissenschaften, volume 76, pages 579-581, 1989. DOI: 10.1007/BF00462870 

[2] J.-L. Deneubourg, S. Aron, S. Goss et J.-M. Pasteels, _The self-organizing exploratory pattern of the Argentine ant_, Journal of Insect Behavior, volume 3, page 159, 1990.

[3] P.P. Grassé, _La reconstruction du nid et les coordinations inter-individuelles chez Belicositermes natalensis et Cubitermes sp. La théorie de la Stigmergie : Essai d'interprétation du comportement des termites constructeurs_, Insectes Sociaux, 6, 1959, pages 41-80.

[4] E. Bonabeau, M. Dorigo M, G. Théraulaz, _Swarm Intelligence. From Natural to Artificial Systems_, Oxford University Press, pages 8-14, 1999.

[5] A. Dutot, F. Guinand, et D. Olivier. _General principles of combinatorial problems solving by ant colony_. In Artificial Ants - From Collective Intelligence to Real-life Optimization and Beyond, édité par Nicolas Monmarché, Frédéric Guinand, et Patrick Siarry, pages 19‑70, 2010.


## HOW TO CITE
Todo !
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

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
0
@#$#@#$#@
