extensions [matrix] ; The matrix extension is used for the creation of the feature matrix

patches-own
[
  since
  plant-species
  plant-energy
]

turtles-own
[
  species
  energy
]

globals
[
  features
  species-list
  available-colors
  current-species-list
  species-colors
  agent-count-list
  plant-species-list
  total-species
]

to setup
  clear-all
  reset-ticks
  create-turtles initial-turtles

  set agent-count-list []
  set total-species 0

  set features create-features

  let plant-species1 create-species ; Dense Forest
  let plant-species2 create-species ; Mountain
  let plant-species3 create-species ; Lake
  let plant-species4 create-species ; Field

  let plant-species-array []
  set plant-species-array insert-item 0 plant-species-array plant-species1
  set plant-species-array insert-item 0 plant-species-array plant-species2
  set plant-species-array insert-item 0 plant-species-array plant-species3
  set plant-species-array insert-item 0 plant-species-array plant-species4
  set plant-species-list plant-species-array

  set species-list []
  add-new-species

  set current-species-list species-list

  set available-colors []
  set available-colors insert-item 0 available-colors black
  set available-colors insert-item 0 available-colors red
  set available-colors insert-item 0 available-colors blue
  set available-colors insert-item 0 available-colors yellow
  set available-colors insert-item 0 available-colors pink
  set available-colors insert-item 0 available-colors white
  set available-colors insert-item 0 available-colors orange
  set available-colors insert-item 0 available-colors gray
  set available-colors insert-item 0 available-colors violet
  set available-colors insert-item 0 available-colors magenta
  set available-colors insert-item 0 available-colors cyan

  set species-colors set-colors

  ask turtles
  [
    set shape "bug"
    set size 1
    set species one-of species-list
    let c find-turtle-color species
    set color c
    set energy energy-constant
    setxy random-xcor random-ycor
  ]

  ask patches
  [
    set plant-species plant-species1
    set plant-energy energy-constant
    set pcolor green
    set since 0
    if pxcor <= 40 and pxcor >= 15 and pycor >= -25 and pycor <= 5
    [
      set plant-species plant-species2
      set plant-energy energy-constant
      set pcolor 104 ;blue lake
    ]

    if pxcor >= -40 and pxcor <= -12 and pycor <= 25 and pycor >= -2
    [
      set plant-species plant-species3
      set plant-energy energy-constant
      set pcolor 7 ;grey mountains
    ]

    if pxcor >= -40 and pxcor <= 0 and pycor >= -25 and pycor <= -3
    [
      set plant-species plant-species4
      set plant-energy energy-constant
      set pcolor 52 ;dark green dense forest
    ]
  ]

  remove-extinct-species
  set current-species-list species-list
end

to go
  ; Creates a new turtle of a random species if all the existing turtles have died
  if count turtles = 0
  [
    create-turtles 1
    ask turtles
    [
      set shape "bug"
      set size 1
      set species create-species
      let c find-turtle-color species
      set color c
      set energy energy-constant
      setxy random-xcor random-ycor
    ]
  ]

  remove-colors
  add-colors

  remove-extinct-species
  set current-species-list []
  set agent-count-list insert-item 0 agent-count-list count turtles

  ask turtles
  [
    let c find-turtle-color species
    set color c

    right random 360
    forward 1

    if not member? species current-species-list [set current-species-list insert-item 0 current-species-list species]

    ifelse count turtles-on patch-here > 1
    [
      let other-agent one-of other turtles-here
      let other-species [species] of other-agent
      let other-energy [energy] of other-agent
      let score1 calculate-score species other-species
      let max-score find-max-score other-species
      let score-difference max-score - score1
      if score-difference < competition-parameter
      [
        let prey-energy eat-agent self other-agent
        set energy energy + (prey-energy * ecological-efficiency)
      ]
    ]
    [
      let plant patch-here
      let p-species [plant-species] of plant
      let p-eating-score calculate-score species p-species
      let max-plant-score find-max-score p-species ; Finds the best score of any species against this plant
      let plant-score-difference max-plant-score - p-eating-score

      if plant-score-difference < competition-parameter
      [
        let p-energy eat-plant self plant
        set energy energy + p-energy
      ]
    ]

    set energy energy - 1 ;Reduces the amount of energy by a constant amount
    if energy <= 0 [die]

    if energy > 100
    [
      reproduce species (energy - 100)
      set energy 100
    ]

    if not member? species species-list [set species-list insert-item 0 species-list species]
  ]

  ask patches
  [
    regrow
  ]

  tick
  update-mean-species
end

; Removes any extinct species from the species list
to remove-extinct-species
  let i 0
  loop
  [
    if not any? turtles with [species = (item i species-list)]
    [
      set species-list remove i species-list
    ]
    if i >= length species-list - 1 [stop]
    set i i + 1
  ]
end

; Returns true or false at random
to-report coin-flip
  report random 2 = 0
end


; After the refractory period for the plant has ended it will regrow so it can be eaten again
to regrow
  if since < 50
  [
    set since since + 1
  ]

  if since >= 50
  [
    set pcolor green
    set since 0
    set plant-energy energy-constant

    if pxcor <= 40 and pxcor >= 15 and pycor >= -25 and pycor <= 5
    [
      set pcolor 104 ;blue lake
    ]

    if pxcor >= -40 and pxcor <= -12 and pycor <= 25 and pycor >= -2
    [
      set pcolor 7 ;grey mountains
    ]

    if pxcor >= -40 and pxcor <= 0 and pycor >= -25 and pycor <= -3
    [
      set pcolor 52 ;dark green dense forest
    ]
  ]
end

; Creates the feature matrix from which species can be created
to-report create-features
  let col_iter 1
  let row_iter 0
  let iter 0
  let all-features matrix:make-constant 500 500 0

  loop
  [
    ;print row_iter
    let rand_num random-float 1
    matrix:set all-features row_iter col_iter rand_num
    matrix:set all-features col_iter row_iter rand_num * -1

    if col_iter = 499 and row_iter = 498 [report all-features]

    set col_iter col_iter + 1
    if col_iter >= 500 [set row_iter row_iter + 1]
    if col_iter >= 500 [set col_iter row_iter + 1]
  ]
end

; Creates a new species from the feature matrix
to-report create-species
  let species-ids list (random 500) (random 500)
  loop
  [
    if length species-ids = 10 [report species-ids]
    set species-ids insert-item 0 species-ids (random 500)
    set species-ids remove-duplicates species-ids
  ]
end

; Calculates the score of one species against another to see whether it can be eaten or not
to-report calculate-score [species1 species2]
  let sums calculate-sums species1 species2
  let scoreij sums / 10
  ifelse scoreij > 0 [report scoreij] [report 0]
end

; Calculates the score sums of one species against another
to-report calculate-sums [species1 species2]
  let alpha-iter 0
  let beta-iter 0
  let sums 0
  loop
  [
    let i item alpha-iter species1
    let j item beta-iter species2
    let m matrix:get features j i ;;;
    set sums sums + m

    if alpha-iter >= 9 and beta-iter >= 9 [report sums]
    set alpha-iter alpha-iter + 1
    if alpha-iter >= 10
    [
      set beta-iter beta-iter + 1
      set alpha-iter 0
    ]
  ]
end

; Finds the highest score that any other alive species has against the species passed
to-report find-max-score [species1]
  let max-score 0
  let iter 0
  loop
  [
    let pred-species item iter current-species-list
    let score calculate-score pred-species species1
    if score > max-score [set max-score score]
    if iter >= length current-species-list - 1 [report max-score]
    set iter iter + 1
  ]
end

; Defines the consequences of one agent eating another agent
to-report eat-agent [pred-agent prey-agent]
  let prey-energy [energy] of prey-agent
  ask prey-agent [die]
  report prey-energy
end

; Defines the consequences of an agent consuming the plant on a patch
to-report eat-plant [pred-agent plant]
  let p-energy [plant-energy] of plant
  set plant-energy 0
  report p-energy
end

; Defines what happens when an agent reproduces
to reproduce [species1 energy-level]
  ; Has a X% chance of randomly mutating a reproduced individual
  if random-chance (1 / (mutation-chance / 100))
  [
    set species1 mutate species1
  ]

  hatch 1
  [
    set species species1
    set energy energy-level
  ]
end

; Outputs true or false with a random probability of 1 / the value supplied
to-report random-chance [value]
  let rand-int random value
  ifelse rand-int = 0 [report true] [report false]
end

; Mutates by changing of the features to a different feature
to-report mutate [species1]
  let rand-int random 10
  set species1 remove-item rand-int species1
  set rand-int random 9
  set species1 remove-item rand-int species1
  set rand-int random 8
  set species1 remove-item rand-int species1
  set rand-int random 7
  set species1 remove-item rand-int species1
  set rand-int random 6
  set species1 remove-item rand-int species1
  loop
  [
    if length species1 = 10 [report species1]
    set species1 insert-item 0 species1 (random 500)
    set species1 remove-duplicates species1
  ]
end

; Creates the food web links so they can be used for visualisation
to-report find-connections
  let i 0
  let j 0
  let current-species item i current-species-list
  let shortened-species-list []
  let food-web-connections []
  loop
  [
    set shortened-species-list remove i current-species-list
    set shortened-species-list insert-item 0 shortened-species-list item 0 plant-species-list ;Allows the plant species to be included in the food web
    set shortened-species-list insert-item 0 shortened-species-list item 1 plant-species-list
    set shortened-species-list insert-item 0 shortened-species-list item 2 plant-species-list
    set shortened-species-list insert-item 0 shortened-species-list item 3 plant-species-list
    let score1 calculate-score current-species item j shortened-species-list
    let max-score find-max-score item j shortened-species-list
    let score-difference max-score - score1
    let connection-array []
    set connection-array insert-item 0 connection-array item j shortened-species-list
    set connection-array insert-item 0 connection-array current-species

    if score-difference < competition-parameter and not member? connection-array food-web-connections
    [
      set food-web-connections insert-item 0 food-web-connections connection-array
    ]

    set j j + 1

    set food-web-connections remove-duplicates food-web-connections

    if j >= length shortened-species-list - 1
    [
      if i >= length current-species-list - 1
      [
        report food-web-connections
      ]
      set i i + 1
      set current-species item i current-species-list
      set j 0
    ]
  ]
end

; Sets the initial colors of the species
to-report set-colors
  let i 0
  let connections-array []
  loop
  [
    let s item i current-species-list
    let connection set-color s
    set connections-array insert-item 0 connections-array connection
    set i i + 1
    if i >= length current-species-list [report connections-array]
  ]
end

; Sets the color of a given species
to-report set-color [s]
  let species-color []
  let c black
  if length available-colors > 0 [set c one-of available-colors]
  set species-color insert-item 0 species-color c
  set available-colors remove c available-colors
  set species-color insert-item 0 species-color s
  report species-color
end

; Gives new species original colors, if more colors are available
to add-colors
  let additions new-colors
  let i 0
  ifelse length additions > 0
  [
    loop
    [
      let s item i additions
      let connection set-color s
      set species-colors insert-item 0 species-colors connection
      set i i + 1
      if i >= length additions [stop]
    ]
  ]
  [stop]

end

; Reports any species that have not been allocated a color
to-report new-colors
  let sc []
  let i 0
  let temp-species-list current-species-list
  loop
  [
    carefully
    [
      set sc item i species-colors
      set temp-species-list remove (item 0 sc) temp-species-list
    ]
    [
    ]
    set i i + 1
    if i >= length species-colors
    [
      report temp-species-list
    ]
  ]
end

; Removes any colors of extinct species so they can be used by new species
to remove-colors
  let i 0
  let sp []
  let new-species-colors species-colors
  let temp-array []
  loop
  [
    set sp item 0 item i species-colors
    let c item 1 item i species-colors
    ifelse member? sp current-species-list []
    [
      set temp-array []
      set temp-array insert-item 0 temp-array c
      set temp-array insert-item 0 temp-array sp
      set new-species-colors remove temp-array new-species-colors
      set available-colors insert-item 0 available-colors c
    ]
    set i i + 1
    if i >= length species-colors
    [
      set species-colors new-species-colors
      stop
    ]
  ]
end

; Finds the species color of a given turtle
to-report find-turtle-color [s]
  let i 0
  loop
  [
    if item 0 item i species-colors = s
    [
      report item 1 item i species-colors
    ]

    set i i + 1
    if i >= length species-colors [report black]
  ]
end

to add-new-species
  let i 0
  loop
  [
    let species1 create-species
    set species-list insert-item 0 species-list species1
    set i i + 1
    if i >= initial-species-number [stop]
  ]
end

; Report the number of each type of species in each area
to-report agents-by-area
  let num-species length current-species-list
  let agent-matrix []
  set agent-matrix insert-item 0 agent-matrix add-matrix-species
  set agent-matrix insert-item 0 agent-matrix add-matrix-species
  set agent-matrix insert-item 0 agent-matrix add-matrix-species
  set agent-matrix insert-item 0 agent-matrix add-matrix-species

  ask turtles
  [
    let agent-s position species current-species-list
    let p-species [plant-species] of patch-here
    let agent-area position p-species plant-species-list
    let area item agent-area agent-matrix
    set area replace-item agent-s area (item agent-s area + 1)
    set agent-matrix replace-item agent-area agent-matrix area
  ]

  report agent-matrix
end

; Initialises an array of zeros with a length equal to the number of species at that time step
to-report add-matrix-species
  let i 0
  let species-array []
  loop
  [
    set species-array insert-item 0 species-array 0
    set i i + 1
    if i >= length current-species-list [report species-array]
  ]
end

to update-mean-species
  set total-species total-species + length current-species-list
end

to-report get-mean
  report total-species / ticks
end
@#$#@#$#@
GRAPHICS-WINDOW
701
11
1762
683
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-40
40
-25
25
1
1
1
ticks
30.0

BUTTON
359
11
423
44
Setup
setup\n
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
435
11
498
44
Go
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

MONITOR
365
639
567
684
Number of Food Web Connections
length find-connections
17
1
11

PLOT
11
10
348
233
Number of Agents
Time
NIL
0.0
200.0
0.0
200.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
11
241
348
455
Number of Species
Time
Species
0.0
100.0
0.0
8.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "carefully[plot length current-species-list][]\n"

PLOT
11
463
348
686
Number of Food Web Connections
Time
NIL
0.0
500.0
0.0
25.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "carefully[plot length find-connections][]"

BUTTON
359
55
547
88
Print Food Web Connections
print plant-species-list\nprint find-connections
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
365
584
478
629
Number of Agents
count turtles
17
1
11

MONITOR
490
584
606
629
Number of Species
length current-species-list
17
1
11

SLIDER
360
146
532
179
ecological-efficiency
ecological-efficiency
0.01
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
360
190
532
223
initial-turtles
initial-turtles
1
200
1.0
1
1
NIL
HORIZONTAL

SLIDER
360
278
532
311
energy-constant
energy-constant
5
50
15.0
5
1
NIL
HORIZONTAL

TEXTBOX
545
274
695
316
Defines the amount of energy \nadded to the environment\neach time a plant regrows
11
0.0
1

TEXTBOX
547
192
697
220
Initial number of turtles\nin the model
11
0.0
1

TEXTBOX
547
156
697
174
Ecological efficiency value
11
0.0
1

SLIDER
360
323
532
356
mutation-chance
mutation-chance
0.1
2
1.0
0.1
1
%
HORIZONTAL

TEXTBOX
544
326
694
354
The chance of a mutation when an offspring is created
11
0.0
1

SLIDER
360
368
535
401
competition-parameter
competition-parameter
0.01
0.5
0.01
0.01
1
NIL
HORIZONTAL

TEXTBOX
545
378
695
396
Competition Parameter Value
11
0.0
1

SLIDER
360
234
532
267
initial-species-number
initial-species-number
1
10
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
545
236
695
264
The number of species the model is initiated with
11
0.0
1

BUTTON
360
99
553
132
Print Agent Numbers by Area
print agents-by-area
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
366
524
533
569
Mean Species Over this Run
get-mean
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

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
NetLogo 6.1.1
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
