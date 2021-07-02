; Model created by Daniël Salomons at Utrecht University
; d.salomons@students.uu.nl
; 6508383

extensions [palette]

globals [
  average-opinion
  average-positive-opinion
  average-negative-opinion
  average-polarisation
]

breed [users user]

users-own [
  opinion
  initial-opinion
  weight
  susceptibility
  grouping
  group-distance
  teleporter?
]

to setup
  clear-all
  set-default-shape users  "face neutral"
  create-users positive-users [set opinion (random-normal  0.25 0.25)]
  create-users negative-users [set opinion (random-normal -0.25 0.25)]
  ask users [
    set initial-opinion opinion
    set susceptibility min list 2 abs(random-normal 0 0.5) ; Less likely to be more susceptible to extreme opinions
    ifelse random-float 1 <= teleporters [set teleporter? true][set teleporter? false]
    setxy random-xcor random-ycor
    set weight 0.1
    set color palette:scale-gradient [[255 0 0] [0 255 0]]  opinion -1 1
    update-grouping
  ]
  track-average-opinion
  reset-ticks
end

to update-grouping
  set grouping abs(opinion) * global-grouping
  set group-distance ceiling(grouping) + 3
end

to update-colors
  ask users  [set color palette:scale-gradient [[255 0 0] [0 255 0]]  opinion -1 1]
end

to track-average-opinion
  let negatives users with [opinion < 0]
  let positives users with [opinion > 0]
  set average-opinion mean([opinion] of users)

  ifelse any? negatives
  [set average-negative-opinion mean([opinion] of negatives)]
  [set average-negative-opinion                            1] ;0

  ifelse any? positives
  [set average-positive-opinion mean([opinion] of positives)]
  [set average-positive-opinion                           -1] ;0

  set average-polarisation average-positive-opinion - average-negative-opinion
end

to go
  if regular-shocks? and (ticks mod 200 = 0) [negative-shock]
  if grouping-over-time? and ticks <= 1000  and (ticks mod 50 = 0) [set global-grouping (ticks / 1000)]
  if ban-radicals? [ask users with [abs(opinion) > 0.95] [die]]
  ask users [
    ifelse opinion > 0 [set shape "face happy"][set shape "face sad"]
    ifelse (random-float 1) > grouping [random-walk][bias-walk]
    if teleporter? and random-float 1 < teleport-odds [teleport-user]
    average-talk-to-neighbours
    update-grouping
  ]
  update-colors
  track-average-opinion

  tick
  if limit-ticks?  [if ticks >= ticklimit [stop]]
  if ticks > 50 and unpolarised-stop and average-polarisation <= 0.83 [stop]
end

to step
  go
end

to average-talk-to-neighbours
  let other-opinions ([opinion] of other users in-radius 3)
  adjust other-opinions
end

to adjust [other-opinions]
  if not empty? other-opinions [
    let op-diff 1 - abs(mean(other-opinions) - opinion)
    let new-opinion (opinion + (0.1 * mean(other-opinions)))
    if abs(initial-opinion - new-opinion) <= susceptibility and abs(new-opinion) <= 1 [
      set opinion new-opinion
    ]
  ]
end

to random-walk
  rt random 90
  lt random 90
  fd 1
end

to bias-walk
  ;; create a point in each direction, measure average opinion, choose opinion that differs the least from yours
  let up (list (xcor - group-distance) (ycor + group-distance))
  let do (list (xcor - group-distance) (ycor - group-distance))
  let ri (list (xcor + group-distance) (ycor + group-distance))
  let le (list (xcor + group-distance) (ycor - group-distance))
  let locations (list up do ri le)
  let destination 0

  ifelse (opposite? and (random-float 1 < opposite-odds))
  [set destination (most-similar locations (-1 * opinion) group-distance)]
  [set destination (most-similar locations opinion group-distance)]
  face (patch (item 0 destination) (item 1 destination))
  fd 1
end

to-report most-similar [locations my-opinion g-d]
  let opinions []
  foreach locations [l ->
    let x (item 0 l)
    let y (item 1 l)
    ask patch x y [
      let ops [opinion] of other users in-radius g-d ;group-distance
      ifelse empty? ops
        ; Agent would rather go to a neutral space than an oppositely biased one
        [set opinions (fput (list 0            (list x y)) opinions)]
        [set opinions (fput (list (mean (ops)) (list x y)) opinions)]
    ]
  ]
  set opinions (sort-by [ [a b] -> abs((item 0 a) - my-opinion) < abs((item 0 b) - my-opinion)] opinions)
  report item 1 (first opinions)
end

to positive-shock
  ask n-of (count users / 2) users [ifelse opinion >=  0.5 [set opinion  1][set opinion (opinion + 0.5)]]
end

to negative-shock
  ask n-of (count users / 2) users [ifelse opinion <= -0.5 [set opinion -1][set opinion (opinion - 0.5)]]
end

to teleport-user
  set heading random 360
  fd abs(random-normal 3 3)
end
@#$#@#$#@
GRAPHICS-WINDOW
218
10
655
448
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
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
6
10
74
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
76
10
143
43
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
145
10
211
43
NIL
step
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
656
10
874
55
Average overall opinion
average-opinion
17
1
11

SLIDER
5
46
106
79
negative-users
negative-users
1
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
107
46
211
79
positive-users
positive-users
1
100
100.0
1
1
NIL
HORIZONTAL

PLOT
656
147
874
282
Average opinion over ticks (time)
ticks
opinion
0.0
1.0
-1.0
1.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -7500403 true "" "plot average-opinion"
"pen-2" 1.0 0 -2674135 true "" "plot average-negative-opinion"
"pen-3" 1.0 0 -13840069 true "" "plot average-positive-opinion"

SLIDER
5
151
210
184
global-grouping
global-grouping
0
0.5
0.5
.05
1
NIL
HORIZONTAL

BUTTON
5
116
108
150
NIL
positive-shock
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
111
116
211
150
NIL
negative-shock
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
656
56
874
101
Average opinion of positive users
average-positive-opinion
17
1
11

MONITOR
656
102
874
147
Average opinion of negative users
average-negative-opinion
17
1
11

SWITCH
0
352
95
385
limit-ticks?
limit-ticks?
1
1
-1000

INPUTBOX
0
387
95
447
ticklimit
1000.0
1
0
Number

PLOT
657
328
875
448
Average polarisation over ticks
NIL
NIL
0.0
1.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot average-polarisation"

MONITOR
657
283
875
328
Average polarisation
average-polarisation
17
1
11

SLIDER
4
187
212
220
teleport-odds
teleport-odds
0
0.9
0.0
0.05
1
NIL
HORIZONTAL

SLIDER
97
262
212
295
opposite-odds
opposite-odds
0
0.5
0.5
0.05
1
NIL
HORIZONTAL

SWITCH
3
262
96
295
opposite?
opposite?
1
1
-1000

SWITCH
100
377
214
410
grouping-over-time?
grouping-over-time?
1
1
-1000

SWITCH
100
343
215
376
regular-shocks?
regular-shocks?
1
1
-1000

SWITCH
5
223
213
256
ban-radicals?
ban-radicals?
1
1
-1000

SWITCH
101
414
215
447
unpolarised-stop
unpolarised-stop
1
1
-1000

SLIDER
5
81
211
114
teleporters
teleporters
0
1
0.0
0.05
1
NIL
HORIZONTAL

@#$#@#$#@
## User grouping model

Model created by Daniël Salomons at Utrecht University, d.salomons@students.uu.nl
Under supervision of dr. Gabriele Keller and dr. Dominik Klein.

Please refer to my student thesis available in the Utrecht University thesis library for more information.
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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment0" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>average-opinion</metric>
    <metric>average-positive-opinion - average-negative-opinion</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping">
      <value value="0"/>
      <value value="0.2"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment1-no-ticklimit" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-positive-opinion - average-negative-opinion</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="grouping" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="ticklimit">
      <value value="5000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-positive-opinion - average-negative-opinion</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="grouping" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="ticklimit">
      <value value="5000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2-100runs-newmodel-noweights" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-positive-opinion - average-negative-opinion</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="global-grouping" first="0" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="ticklimit">
      <value value="5000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="grouping0.3-distance4-variable-ask-radius" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-positive-opinion - average-negative-opinion</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group-distance">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ask-radius" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="grouping">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-rooting-grouping" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-positive-opinion - average-negative-opinion</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <steppedValueSet variable="opinion-rooting" first="2" step="2" last="10"/>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="grouping" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="ticklimit">
      <value value="5000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="groupdistance-vs-askradius" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-positive-opinion - average-negative-opinion</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="group-distance" first="3" step="3" last="9"/>
    <steppedValueSet variable="ask-radius" first="3" step="3" last="9"/>
    <enumeratedValueSet variable="grouping">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="teleports" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="teleport-odds" first="0" step="0.2" last="0.8"/>
    <enumeratedValueSet variable="global-group-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="filter" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-polarisation</metric>
    <steppedValueSet variable="filter-threshold" first="0.2" step="0.2" last="1"/>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-distance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="93"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="teleport distance" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="filter-threshold">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opinion-rooting">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="teleport-distance" first="1" step="2" last="5"/>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ask-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="tban" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="teleport-distance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timed-ban-radicals?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="teleport-unpolarisation-odds" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>average-polarisation</metric>
    <steppedValueSet variable="teleport-distance" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="opposites" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="teleport-distance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="opposite-odds" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="opposite?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="new-baseline" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="teleport-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleporters">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="global-grouping" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1000teleports distance3 telepoerters100" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="teleport-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="teleport-odds" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleporters">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1000teleports distance3 telepoerters0 - 100 todds0.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="teleport-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="teleporters" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1000teleports distance3 telepoerters0 - 100 todds0.2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="teleport-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="teleporters" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1000teleports distance3 telepoerters0 - 100 todds0.3" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="teleport-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="teleporters" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="op-diff-weight">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="tidst-td01-tg03" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>average-polarisation</metric>
    <enumeratedValueSet variable="regular-shocks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleport-odds">
      <value value="0.3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="teleport-distance" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="negative-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-ticks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite-odds">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="opposite?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ticklimit">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teleporters">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ban-radicals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-group-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unpolarised-stop">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grouping-over-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-grouping">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
