globals [
  action ;;last button pressed. left = 1, right = 2
  object-x ;;the object's current position
  object-y
  push-force
  global-speed ;;for plotting @?
  global-d-speed
  win? ;;to see if they've won
  score
  last-score ;;for coding purposes, keeping track of the previous score (to see if it's changed)
  season
  timer-running?

  timer-at-end ;;timer at time of win/deaths

  nr-of-pushes

  energy ;;the player's energy (keeping it in a global variable for now) @change this?

  mouse-was-down?
  mouse-dist ;;distance from mouse-down point to object
  mouse-acc
  old-mouse-x ;;keeping track of whether the mouse has been moved
  old-object-x ;;keeping track for mgraphics (mouse) purposes
  update-mgraphics?
  mouse-divisor
]

breed [houses house] ;;needs to be a breed only so it can be in the background layer
breed [objects object]
breed [players player]
breed [graphics graphic] ;;sparks
breed [mgraphics mgraphic] ;;mouse-related graphics

players-own [
  force
  ;;@energy
]

objects-own [
  speed
  old-speed
  d-speed
  mass
  object-friction
  points
]

graphics-own [lifetime name]
mgraphics-own [lifetime name]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;KRÆFTER OG BEVÆGELSE;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set season "summer" ;;default season
  make-world
  make-object ;;the one that's chosen

  set win? false
  set timer-running? false
  set nr-of-pushes 0
  set energy start-energy ;;@

  set mouse-was-down? FALSE

  reset-ticks
end

to go
  ;;if not timer-running? [reset-timer] ;;first time go is pressed, timer is reset @CHANGE THIS so it's after the first push
  ;;set timer-running? TRUE

 ;; every 2 / hastighed [do-mouse-stuff] ;;@figure out how this is best visualised, related to model running speed

  every 3 / hastighed   [

    if count objects > 0 [
      set object-x [xcor] of one-of objects
      set object-y [ycor] of one-of objects] ;;there'll always only be one object at a time

    do-mouse-stuff

    move

    ;;do-mouse-stuff ;;figure out how to make this fit with hastighed/make it show
    accelerate-object
    check-win
    update-graphics

    every 1 [tick] ;;@change the tick speed?
    ;;do-mouse-stuff

  ]
end

to move
  move-person
  every 0.5
    [check-object] ;;to see if they've failed
end

to do-mouse-stuff

  if old-mouse-x != mouse-xcor or old-object-x != object-x [ ask mgraphics [die] set update-mgraphics? TRUE ] ;;@update visuals only if mouse or object position has changed

  if update-mgraphics? [

  if mouse-down? [
    create-mgraphics 1 [
      set size 1
      set color yellow
      set shape "circle"
      setxy (mouse-xcor) (object-y) ;;@mouse-ycor instead?
      set lifetime 1 ;;@?
      set name "mouse-dot"
    ]

    let distanabs (mouse-xcor - object-x)

    create-mgraphics 1 [ ;;dot in the middle of the object
    set size 1
    set color yellow
    set shape "circle"
    setxy (object-x) (object-y)
    set lifetime 1
    set name "object-dot"
    let turtle-number item 0 [who] of mgraphics with [name = "mouse-dot"] ;;the nr of the turtle under the mouse
    create-link-with turtle turtle-number [set thickness 0.5 set color yellow set mouse-dist link-length] ;;visual link showing distance
    ]


    ];;if mouse down end
  ];;if update-mgraphics?


  if not mouse-down? [
    set mouse-dist 0
    set mouse-acc 0 ;;accelerationsvektoren tilføjes kun så længe musen stadig er holdt nede
  ]


  if mouse-down? [ ;;to avoid division by 0

    ;;ADD THE ACCELERATION VECTOR BASED ON THE DISTANCE
    set mouse-divisor scaling-mouse / mouse-dist ;;/ scaling-mouse ;;@ testing size of scaling-mouse in interface

    set mouse-acc (- (mouse-dist)^ 2 ) / mouse-divisor ;;proportionel med kvadratet på afstanden ;;(og så lineært skaleret ned)

    if mouse-xcor > object-x [set mouse-acc (mouse-acc)] ;;if pushing left, subtract push-force instead of adding it (negative speed = left)
  if mouse-xcor < object-x [set mouse-acc (- mouse-acc)]
  ]

  set push-force mouse-acc ;;push-force is added to d-speed in accelerate-object
 ;; print push-force

  set old-mouse-x mouse-xcor ;;to check next run through if mouse position has changed ;;@delete?
  set old-object-x object-x
end



;;accelerationsvektor (+ hvis spilleren skubber) m/s^2
;;fartvektor
;;hvert tick: læg acc-vek til fart-vek, bevæg spilleren (objektet) ift bevægelsesvektoren

to accelerate-object
  ask objects [
    ;;calculate the acceleration vector (d-speed)

;;print word "push-force: " push-force
    ;; + skubbekraften
   set d-speed d-speed + push-force ;;push-force is positive if going right, negative if going left

    set global-d-speed d-speed

    ;; - resistance @(what sort of resistance is this?) ;;the resistance depends on the speed (see the resistance reporter)
        ;;modstanden er proportionel med kvadratet på hastigheden (hvis man fordobler hastigheden, firedobler man modstanden)

    if speed > 0 [set d-speed d-speed - resistance] ;;if currently going right, resistance towards left
    if speed < 0 [set d-speed d-speed + resistance] ;;if currently going left, resistance towards right

;;print word "d-speed :" d-speed

    ;;add the acceleration vector to the speed
    set old-speed speed ;;the previous speed

    set speed speed + d-speed ;;d-speed is the resulting force/acceleration vector of all the factors

    set push-force 0 ;;reset the skubbekraft once it has been applied
    set d-speed 0 ;;reset the acceleration vector once it has been applied

    if speed < lower-limit and speed > 0 [set speed 0] ;;to the right ;;@tweak this (otherwise it never quite reaches 0)
    if speed > (- lower-limit) and speed < 0 [set speed 0] ;;to the left

    set speed precision speed 5 ;;@precision can be tweaked

    set global-speed speed ;;testing, plots all the time
    ;;if old-speed != speed [set global-speed speed] ;;for plotting only when the speed changes @?
  ]

  ;;and now move!
  ask objects [


    forward speed ;;'forward' means to the right (90) if positive number and to the left if negative
; if speed > 0 [print word "speed: " speed]
    ]

 ;;SPARKS
  ask patch (object-x) (object-y - 2) [
    if (global-speed > 0 or global-speed < 0) and season != "winter" [ ;;only if the object is moving and it's not winter (ice = 'no' friction)

    sprout-graphics 2 [
      set shape "star" set color yellow set size 0.7 set lifetime 0

        let rando random 2 ;;random little way to set random heading in one of two intervals
        ifelse rando = 1
          [set heading 270 + (random 91)] ;;somewhere between 270 and 360
          [set heading random 91] ;;between 0 and 90

  ]]]

end


to-report resistance
  report speed ^ 2 / resistance-divisor ;;@now fixed, should change
end


to check-win
;;  let object-position round [

  ask houses [
    let win-patches (patch-set patch-here [neighbors] of patch-here)
    ask win-patches [
      let the-object one-of objects-here
      if the-object != nobody [
        if [speed < 0.03] of the-object [
          set win? TRUE
        ]
      ]
  ]
  ]


  if win? [
    set timer-at-end precision timer 2 ;;save how long it took them to win
    ;;@keep tally of the nr of pushes used for each level here as well? a list?

    set last-score score
    set score score + 1
    ask objects [die]
    ask players [set shape "person"]
    ask patch (max-pxcor - (max-pxcor / 2)) (max-pycor - 5) [set plabel (word "Nice! You took " (timer-at-end) " seconds and used " nr-of-pushes " pushes.") ]
    ask patch (max-pxcor - (max-pxcor / 2) - 8) (max-pycor - 8) [set plabel"Now onto the next thing!"]

    set timer-running? FALSE ;;so the timer can start over again with their next first push

    set win? FALSE
    set global-speed 0 set global-d-speed 0


  ]

end

to update-graphics
  if score != last-score [ ask patch (max-pxcor - 1) (max-pycor - 1) [set plabel (word "Score:" score)] ] ;;update score counter

  ;;ask patch (min-pxcor + 1) (max-pycor - 1) [set plabel ticks] ;;simple timer counter in ticks (not needed?) (right now approximately a second)

  ifelse win? [
     ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (precision timer-at-end 2)] ;;if won, freeze visual timer at end time
  ]
  [
    ifelse timer-running? [
      ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (precision timer 1)] ;;otherwise show it ticking away (if the timer is running)
    ]
    [
      ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (0)] ;;if timer shouldn't be running, just show 0
    ]
  ]


  ask graphics [ ;;the visual sparks
    forward 1
    set lifetime lifetime + 1
    if lifetime >= 2[die]
  ]
end


to check-object ;;to see if they've failed and pushed it over the edge
  if any? objects with [pxcor > (max-pxcor - 10)] [ ;;if the object has fallen over the edge
    ask objects [
      setxy (max-pxcor - 5) -17] ;;@apply gravity to actually make them fall down instead!

    ask players [set shape "person"]
    user-message "You failed! :-( Try again!"
    play-level ;;starts the level over
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;;;MOVING THE PLAYER;;;
;;;;;;;;;;;;;;;;;;;;;;;

to move-person
  if action != 0 [
    if action = 1 [
      move-left
    ]
    if action = 2 [
      move-right
    ]

      set action 0
  ]
end

to move-left
  ask players [
    setxy (object-x + 1) 0
    set shape "pushing-left"
  ]

  if not timer-running? [reset-timer] ;;if it's the very first push, start the timer
  set timer-running? TRUE

  set push-force (push-force - push) ;;pushing to the left means negative push-force in these calculations (negative speed = going to the left)

  set nr-of-pushes nr-of-pushes + 1

  check-object
end

to move-right
 ask players [
    ifelse object-x > min-pxcor + 1
        [setxy (object-x + -1) 0] ;;@
        [setxy min-pxcor 0]
    set shape "pushing-right"
  ]

  if not timer-running? [reset-timer] ;;if it's the very first push, start the timer
  set timer-running? TRUE

  set push-force push-force + push

  set nr-of-pushes nr-of-pushes + 1

  check-object
end


;;;GRAPHICS;;;

to make-world
  ask players [die]
  ask objects [die]

  if season = "summer" [
  ask patches [ ;;summer sky and grass
    ifelse pycor > -2 or (pxcor > (max-pxcor - 10) and pycor > -19)  [set pcolor sky] [ set pcolor scale-color green ((random 500) + 5000) 0 9000 ] ;;summer
  ]]

  if season = "winter" [
    ask patches [ ;;winter sky and snow
    ifelse pycor > -2 or (pxcor > (max-pxcor - 10) and pycor > -19)  [set pcolor 94] [ set pcolor scale-color white ((random 500) + 8000) 0 9000 ]
    if pycor < -1 and pycor > -3 and pxcor < (max-pxcor - 9) [set pcolor scale-color 88 ((random 500) + 7000) 0 9000] ;;and ice
  ]]

   create-houses 1 [ ;;the house
    set shape "house"
    set color 24
    set size 3
    setxy (max-pxcor - 13) 0
  ]

  create-players 1 [ ;;the player
    set shape "person"
    set color black
    set size 2.8
    setxy (min-pxcor + 1) 0
  ]

  ask patch (max-pxcor - 1) (max-pycor - 1) [set plabel (word "Score:" score)] ;;the score counter
end


;;OBJECTS
to make-object
  ask objects [die]
  set push-force 0

  ask patch (max-pxcor - (max-pxcor / 2)) (max-pycor - 5) [set plabel ""] ;;the patches displaying the 'nice work!' after the previous completion
  ask patch (max-pxcor - (max-pxcor / 2) - 8) (max-pycor - 8) [set plabel""]

  if level = "1 - sheep" [
  create-objects 1 [
    set shape "sheep"
    set color white
    set size 3
    setxy (min-pxcor + 4) 0
    set heading 90 ;;so positive speed means going to the right, negative to the left
    set mass choose-mass ;;@ADD fixed mass here
    set points 100
  ]]

  if level = "2 - car" [
  create-objects 1 [
    set shape "car2" ;;car 2 is my modified non-floating shape
    set color 7
    set size 3
    setxy (min-pxcor + 4) 0
    set heading 90 ;;so positive speed means going to the right, negative to the left
    set mass choose-mass ;;@ADD fixed mass here
    set points 100
  ]]

  ;;@add more objects/levels here
end

to play-level
  make-object
  ask players [setxy (min-pxcor + 1) 0 set shape "person"]
  set push-force 0
  ask objects [set speed 0]
  set nr-of-pushes 0 ;;@could save a total nr of pushes across levels?
  set timer-running? FALSE ;;so the timer can start over again with their first push

end


to-report show-timer
  ifelse timer-running? [
    report timer
  ]
  [
    report "Spillet kører ikke endnu"
  ]
end


;;@TESTING OUT MOUSE CLICK STUFF

;;@MAKING THIS A GLOBAL INSTEAD
;;to-report mouse-was-down?
  ;;ifelse mouse-down? [report TRUE][report FALSE]
;;end






@#$#@#$#@
GRAPHICS-WINDOW
210
10
950
511
-1
-1
12.0
1
16
1
1
1
0
0
0
1
-30
30
-20
20
0
0
1
ticks
30.0

BUTTON
40
160
103
193
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
115
160
178
193
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
1305
10
1367
43
LEFT
set action 1
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

BUTTON
1370
10
1437
43
RIGHT
set action 2
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

INPUTBOX
1305
220
1380
280
choose-mass
2.0
1
0
Number

INPUTBOX
1380
220
1440
280
gravity
9.8
1
0
Number

MONITOR
52
375
192
420
current resistance
min [resistance] of objects
17
1
11

INPUTBOX
50
10
100
70
push
0.2
1
0
Number

MONITOR
50
420
190
465
current object speed
min [speed] of objects
17
1
11

MONITOR
50
465
190
510
NIL
min [d-speed] of objects
17
1
11

BUTTON
960
10
1025
43
winter
set season \"winter\"\nmake-world\nmake-object
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
960
50
1025
83
summer
set season \"summer\"\nmake-world\nmake-object
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
980
285
1460
510
plot 1
NIL
NIL
0.0
10.0
0.0
0.4
true
true
"" ""
PENS
"speed" 1.0 0 -8053223 true "" "plot global-speed"
"delta-speed" 1.0 0 -1184463 true "" "plot global-d-speed"
"push-force" 1.0 0 -13840069 true "" "plot push-force"
"0" 1.0 0 -7500403 true "" "plot 0"

INPUTBOX
110
10
175
70
lower-limit
0.05
1
0
Number

MONITOR
120
330
192
375
NIL
push-force
17
1
11

INPUTBOX
70
75
165
135
resistance-divisor
10.0
1
0
Number

MONITOR
960
100
1017
145
NIL
score
17
1
11

CHOOSER
30
200
122
245
level
level
"1 - sheep" "2 - car" "3 - something"
1

BUTTON
130
200
190
245
NIL
play-level
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
1

SLIDER
1075
15
1247
48
hastighed
hastighed
1
100
82.0
1
1
%
HORIZONTAL

MONITOR
1065
105
1285
150
NIL
show-timer
17
1
11

MONITOR
1300
105
1357
150
NIL
ticks
17
1
11

MONITOR
960
170
1035
215
NIL
nr-of-pushes
17
1
11

MONITOR
960
220
1017
265
NIL
energy
17
1
11

INPUTBOX
1025
220
1090
280
start-energy
100.0
1
0
Number

INPUTBOX
85
255
180
315
scaling-mouse
1000.0
1
0
Number

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

car2
false
0
Polygon -7500403 true true 300 210 279 194 261 174 240 165 226 162 213 136 203 114 185 93 159 80 135 80 75 90 0 180 0 195 0 255 300 255 300 210
Circle -16777216 true false 180 210 90
Circle -16777216 true false 30 210 90
Polygon -16777216 true false 162 110 132 108 134 165 209 165 194 135 189 126 180 119
Circle -7500403 true true 47 225 58
Circle -7500403 true true 195 225 58

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

pushing-left
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 120 90 120 195 120 285 105 300 135 300 150 225 180 255 195 300 225 300 195 195 180 105
Rectangle -7500403 true true 135 75 172 94
Polygon -7500403 true true 120 90 60 90 60 105 120 120
Polygon -7500403 true true 135 120 75 135 60 150 120 150
Circle -7500403 true true 150 90 30
Rectangle -7500403 true true 120 90 165 120
Circle -7500403 true true 45 75 30
Circle -7500403 true true 45 120 30
Rectangle -7500403 true true 45 75 60 105
Rectangle -7500403 true true 45 120 60 150

pushing-right
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 180 90 180 195 180 285 195 300 165 300 150 225 120 255 105 300 75 300 105 195 120 105
Rectangle -7500403 true true 128 75 165 94
Polygon -7500403 true true 180 90 240 90 240 105 180 120
Polygon -7500403 true true 165 120 225 135 240 150 180 150
Circle -7500403 true true 120 90 30
Rectangle -7500403 true true 135 90 180 120
Circle -7500403 true true 225 75 30
Circle -7500403 true true 225 120 30
Rectangle -7500403 true true 240 75 255 105
Rectangle -7500403 true true 240 120 255 150

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
1
@#$#@#$#@
