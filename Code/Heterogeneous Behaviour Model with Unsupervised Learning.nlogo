extensions
[
  matrix
  py
]

patches-own
[
  since
  plant-defence
  plant-energy
]

turtles-own
[
  predatory-ability
  plant-eating-ability
  defence
  speed
  metabolism
  energy
  species
]

globals
[
  original-species
  species-list
  available-colors
  species-colors
  total-species
]

to setup
  clear-all
  reset-ticks
  create-turtles 1

  ; Python setup
  py:setup py:python
  py:run "from sklearn.cluster import DBSCAN"
  py:run "from sklearn import metrics"
  py:run "from sklearn.datasets import make_blobs"
  py:run "from sklearn.preprocessing import StandardScaler"
  py:run "from sklearn.cluster import MeanShift"
  py:run "from sklearn.cluster import AgglomerativeClustering"
  py:run "from sklearn.cluster import Birch"
  py:run "from sklearn.cluster import AffinityPropagation"
  py:run "import numpy as np"
  py:run "from sklearn.cluster import OPTICS"

  set total-species 0

  set original-species []
  set original-species insert-item 0 original-species random-float 5
  set original-species insert-item 0 original-species 0.5 ;random-float 1
  set original-species insert-item 0 original-species 0.5 ;random-float 1
  set original-species insert-item 0 original-species 0.5 ;random-float 1
  set original-species insert-item 4 original-species ((item 0 original-species + item 1 original-species + item 2 original-species + (item 3 original-species / 5))) ;3 *

  set species-list []

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

  ask turtles
  [
    set shape "bug"
    set size 1
    set predatory-ability item 0 original-species
    set plant-eating-ability item 1 original-species
    set defence item 2 original-species
    set speed item 3 original-species
    set metabolism item 4 original-species

    set energy energy-constant
    setxy random-xcor random-ycor
  ]

  ask patches
  [
    set plant-energy energy-constant
    set pcolor green
    set plant-defence 0.1

    set since 0
    if pxcor <= 40 and pxcor >= 15 and pycor >= -25 and pycor <= 5
    [
      set pcolor 104 ;blue lake
      set plant-defence 0.2
      set plant-energy energy-constant
    ]

    if pxcor >= -40 and pxcor <= -12 and pycor <= 25 and pycor >= -2
    [
      set pcolor 7 ;grey mountains
      set plant-defence 0.3
      set plant-energy energy-constant
    ]

    if pxcor >= -40 and pxcor <= 0 and pycor >= -25 and pycor <= -3
    [
      set pcolor 52 ;dark green dense forest
      set plant-defence 0.4
      set plant-energy energy-constant
    ]
  ]

  set species-list find-species
  set species-colors set-colors
  ask turtles
  [
    let c find-turtle-color species
    set color c
  ]
end

to go
  ; Creates a new turtle of a random species if all the existing turtles have died
  if count turtles = 0
  [
    create-turtles 1
    set original-species []
    set original-species insert-item 0 original-species random-float 5
    set original-species insert-item 0 original-species random-float 1
    set original-species insert-item 0 original-species random-float 1
    set original-species insert-item 0 original-species random-float 1
    set original-species insert-item 4 original-species ((item 0 original-species + item 1 original-species + item 2 original-species + (item 3 original-species / 5)))

    ask turtles
    [
      set shape "bug"
      set size 1
      set predatory-ability item 0 original-species
      set plant-eating-ability item 1 original-species
      set defence item 2 original-species
      set speed item 3 original-species
      set metabolism item 4 original-species

      set energy energy-constant
      setxy random-xcor random-ycor
    ]
  ]

  remove-colors
  add-colors

  let average-plant-ability mean [plant-eating-ability] of turtles
  let average-pred-ability mean [predatory-ability] of turtles

  ask turtles
  [
    right random 360
    forward speed

    let p-defence [plant-defence] of patch-here
    let avg-pred-ability mean [predatory-ability] of turtles with [species = species]
    let avg-plant-ability mean [plant-eating-ability] of turtles with [species = species]

    ifelse count turtles-on patch-here > 1
    [
      let other-agent one-of other turtles-here
      ifelse predatory-ability * (random-float 2) > [defence] of other-agent and [species] of other-agent != species and (avg-plant-ability / average-plant-ability) <= (avg-pred-ability / average-pred-ability) ;and predatory-ability >= plant-eating-ability ;predatory-ability - average-pred-ability >= plant-eating-ability - average-plant-ability
      [
        set energy energy + eat-agent self other-agent
      ]
      [
        if plant-eating-ability * (random-float 2) > p-defence and (avg-plant-ability / mean [plant-eating-ability] of turtles) >= (avg-pred-ability / mean [predatory-ability] of turtles);and predatory-ability < plant-eating-ability ;predatory-ability - average-pred-ability <= plant-eating-ability - average-plant-ability
        [
          set energy energy + eat-plant self patch-here
        ]
      ]
    ]
    [
      if plant-eating-ability * (random-float 2) > p-defence and (avg-plant-ability / mean [plant-eating-ability] of turtles) >= (avg-pred-ability / mean [predatory-ability] of turtles);and predatory-ability < plant-eating-ability ;predatory-ability - average-pred-ability <= plant-eating-ability - average-plant-ability
      [
        set energy energy + eat-plant self patch-here
      ]
    ]


    set energy energy - metabolism
    if energy <= 0 [die]

    if energy > 100 [reproduce self]
  ]

  ask patches
  [
    regrow
  ]

  set species-list find-species
  ask turtles
  [
    let c find-turtle-color species
    set color c
  ]

  tick
  update-mean-species
end

; returns true or false at random
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
    let p-max 1
    carefully [set p-max [plant-eating-ability] of max-one-of turtles [plant-eating-ability]] [set p-max 1]

    carefully
    [
      set plant-energy energy-constant ;energy-constant
      set pcolor green
      set plant-defence mean [plant-eating-ability] of turtles * 0.5

      set since 0
      if pxcor <= 40 and pxcor >= 15 and pycor >= -25 and pycor <= 5
      [
        set pcolor 104 ;blue lake
        set plant-defence mean [plant-eating-ability] of turtles * 1
        set plant-energy energy-constant
      ]

      if pxcor >= -40 and pxcor <= -12 and pycor <= 25 and pycor >= -2
      [
        set pcolor 7 ;grey mountains
        set plant-defence mean [plant-eating-ability] of turtles * 1.1
        set plant-energy energy-constant
      ]

      if pxcor >= -40 and pxcor <= 0 and pycor >= -25 and pycor <= -3
      [
        set pcolor 52 ;dark green dense forest
        set plant-defence mean [plant-eating-ability] of turtles * 2.5
        set plant-energy 50
      ]
    ][]
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
  ;set pcolor brown
  set plant-energy 0
  report p-energy
end

; Defines what happens when an agent reproduces
to reproduce [current-agent]
  ; Currently always mutates
  ifelse random-chance 250
  [
    hatch 1
    [
      set predatory-ability big-mutation [predatory-ability] of current-agent
      set plant-eating-ability big-mutation [plant-eating-ability] of current-agent
      set defence big-mutation [defence] of current-agent
      set speed 1
      set metabolism (predatory-ability + (plant-eating-ability * 2) + (defence) + (speed / 5))

      set energy [energy] of current-agent - 100
    ]
  ]
  [
    hatch 1
    [
      set predatory-ability mutate [predatory-ability] of current-agent
      set plant-eating-ability mutate [plant-eating-ability] of current-agent
      set defence mutate [defence] of current-agent
      set speed 1
      set metabolism (predatory-ability + (plant-eating-ability * 2) + (defence) + (speed / 5))

      set energy [energy] of current-agent - 100
    ]
  ]

  ask current-agent [set energy 100]
end

; Mutates a given feature by a small amount proportional to its current value
to-report mutate [feature]
  let change-value feature / 10
  let new-value feature

  ifelse random-chance 2
  [
    set new-value new-value + change-value
  ]
  [
    set new-value new-value - change-value
  ]

  report new-value
end

; Mutates a given feature by a small amount proportional to its current value
to-report big-mutation [feature]
  let change-value 0.2
  let new-value feature

  ifelse random-chance 2
  [
    set new-value new-value + change-value
  ]
  [
    set new-value new-value - change-value
  ]

  if new-value < 0 [set new-value 0]

  report new-value
end

; Outputs true or false with a random probability of 1 / the value supplied
to-report random-chance [value]
  let rand-int random value
  ifelse rand-int = 0 [report true] [report false]
end


to-report find-species
  let agent-list []
  set species-list []

  carefully
  [
    ask turtles
    [
      let s-array []
      set s-array insert-item 0 s-array predatory-ability
      set s-array insert-item 0 s-array plant-eating-ability
      set s-array insert-item 0 s-array defence

      set agent-list insert-item 0 agent-list s-array
    ]

    py:set "training_data" agent-list
    py:run "X = StandardScaler().fit_transform(training_data)"
    py:run "y = DBSCAN(eps = 0.6, min_samples = 3).fit(X)" ;0.6 3
    py:run "labels = y.labels_"

    set species-list py:runresult "labels"
    let temp-list species-list

    ask turtles
    [
      set species item 0 temp-list
      set temp-list remove-item 0 temp-list
    ]
  ]
  [

  ]

  set species-list remove-duplicates species-list


  report species-list
end




; Creates an array
to-report create-species-array
  let s-array []
  let i 0

  loop
  [
    set s-array insert-item 0 s-array []
    set i i + 1
    if i >= length species-list [report s-array]
  ]
end




to-report find-connections
  let food-web-connections find-world-connections
  let i 0
  let j 0

  if length species-list <= 1 [report food-web-connections]

  loop
  [
    let shortened-species-list remove i species-list

    let current-species item i species-list
    let opponent-species item j shortened-species-list
    let avg-pred-ability mean [predatory-ability] of turtles with [species = current-species]
    let avg-plant-ability mean [plant-eating-ability] of turtles with [species = current-species]
    let avg-defence mean [defence] of turtles with [species = opponent-species]
    let avg-pred2 mean [predatory-ability] of turtles with [species = opponent-species]

    let max-pred-ability max [predatory-ability] of turtles with [species = current-species]

    if avg-pred-ability > avg-defence and current-species != opponent-species and avg-pred-ability > avg-pred2 and (avg-plant-ability / mean [plant-eating-ability] of turtles) <= (avg-pred-ability / mean [predatory-ability] of turtles)
    [
      let connection []
      set connection insert-item 0 connection opponent-species
      set connection insert-item 0 connection current-species

      if not member? connection food-web-connections [set food-web-connections insert-item 0 food-web-connections connection]
    ]


    set j j + 1
    if j >= length shortened-species-list
    [
      set i i + 1
      ifelse i >= length species-list [report food-web-connections][set j 0]
    ]
  ]
end





; Finds the food web connections between species and the plants in the environment
to-report find-world-connections
  let food-web-connections []
  let i 0

  if length species-list = 0 [report food-web-connections]

  loop
  [
    let current-species item i species-list
    let avg-pred-ability mean [predatory-ability] of turtles with [species = current-species]
    let avg-plant-ability mean [plant-eating-ability] of turtles with [species = current-species]
    let avg-pred2 mean [predatory-ability] of turtles

    let max-pred-ability max [predatory-ability] of turtles with [species = current-species]
    let max-plant-ability max [plant-eating-ability] of turtles with [species = current-species]

    if (avg-plant-ability / mean [plant-eating-ability] of turtles) >= (avg-pred-ability / mean [predatory-ability] of turtles) ;avg-pred-ability >= avg-plant-ability
    [
      if avg-plant-ability > mean [plant-eating-ability] of turtles * 0.5
      [
        let connection []
        set connection insert-item 0 connection "Plant 1"
        set connection insert-item 0 connection current-species

        if not member? connection food-web-connections [set food-web-connections insert-item 0 food-web-connections connection]
      ]

      if avg-plant-ability > mean [plant-eating-ability] of turtles * 0.75
      [
        let connection []
        set connection insert-item 0 connection "Plant 2"
        set connection insert-item 0 connection current-species

        if not member? connection food-web-connections [set food-web-connections insert-item 0 food-web-connections connection]
      ]

      if avg-plant-ability > mean [plant-eating-ability] of turtles
      [
        let connection []
        set connection insert-item 0 connection "Plant 3"
        set connection insert-item 0 connection current-species

        if not member? connection food-web-connections [set food-web-connections insert-item 0 food-web-connections connection]
      ]

      if avg-plant-ability > mean [plant-eating-ability] of turtles * 1.25
      [
        let connection []
        set connection insert-item 0 connection "Plant 4"
        set connection insert-item 0 connection current-species

        if not member? connection food-web-connections [set food-web-connections insert-item 0 food-web-connections connection]
      ]
    ]

    set i i + 1
    if i >= length species-list [report food-web-connections]
  ]
end

; Sets the initial colors of the species
to-report set-colors
  let i 0
  let connections-array []
  if length species-list <= 0 [report connections-array]
  loop
  [
    let s item i species-list
    let connection set-color s
    set connections-array insert-item 0 connections-array connection
    set i i + 1
    if i >= length species-list [report connections-array]
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
  let temp-species-list species-list
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
    if length species-colors = 0 [stop]
    set sp item 0 item i species-colors
    let c item 1 item i species-colors
    ifelse member? sp species-list []
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
    if length species-colors = 0 [report black]
    if item 0 item i species-colors = s
    [
      report item 1 item i species-colors
    ]

    set i i + 1
    if i >= length species-colors [report black]
  ]
end

to update-mean-species
  set total-species total-species + length species-list
end

to-report get-mean
  report total-species / ticks
end
@#$#@#$#@
GRAPHICS-WINDOW
580
10
1641
682
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
361
152
474
197
Number of Agents
count turtles
17
1
11

SLIDER
361
62
533
95
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
361
112
533
145
energy-constant
energy-constant
5
50
15.0
5
1
NIL
HORIZONTAL

PLOT
9
14
348
202
Predatory Ability Vs Plant Eating Ability Vs Defence
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Predatory Ability" 1.0 0 -13345367 true "" "carefully\n[\n  plot mean [predatory-ability] of turtles\n]\n[]"
"Defence" 1.0 0 -2674135 true "" "carefully\n[\n  plot mean [defence] of turtles\n]\n[]"
"Plant Eating" 1.0 0 -13840069 true "" "carefully\n[\n  plot mean [plant-eating-ability] of turtles\n]\n[]"

MONITOR
361
202
477
247
Number of Species
length find-species
17
1
11

PLOT
9
210
348
415
Number of Species
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "carefully\n[\n  plot length find-species\n][]"

PLOT
8
421
294
588
Number of Agents
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

BUTTON
354
302
512
335
Print Species List
print species-list
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
354
380
574
413
Number of Food Web Connections
print length find-connections
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
301
421
571
588
Number of Connections
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot length find-connections"

BUTTON
354
341
542
374
Print Food Web Connections
print find-connections
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
361
252
524
297
Mean Species Ovet his Run
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
