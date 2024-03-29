globals
[
 turn ;;keeps track of what turn it is
 old-food-supply ;;just for output message of how it changes each round
 old-food-supply2 ;;just for prognosis - at the END of a round (pressing play), it still holds the food supply from the end of last round
 food-supply ;;the shared food supply
 max-take ;;each student's proportion of the food/how much they're allowed to take
 last-total-taken ;;keeping track of how much food gets taken each turn (resets each turn)
 all-time-taken ;;how much has ever been taken
 current-function ;;to display the linear function used for multiplication

 update-monitors? ;;for other plots updating
 clear-prognosis? ;;to restart the plot before each prognosis
 current-prognosis ;;@add this
 n ;;used for the prognosis iteration
 last-n ;;for prognosis iterations ;;@delete? is it in use?
 old-food-prog ;;used in prognosis
 death-day ;;how many days until they run out of food if they continue like this! (from prognosis)


 good-patches ;;to figure out where to place the student avatars (just visual) ;;stolen from public good model
 invisibles
 greedy-list ;;storing the students who took more food this round than last round (overwritten every round)
 humble-list
 greedy-list-%
 humble-list-%
 all-ready? ;;to check if ready to play
]

breed [students student]
breed [invisibles1 invisible1]
breed [invisibles2 invisible2] ;;purely for goodpatches layout purposes
breed [banners banner] ;;dummy turtles for the students' labels (to change their position)
breed [standins standin]

students-own [
  user-id ;;the client name (
  my-name ;;the turtle 'self' name used for display
  base-color ;;their color (when they're not signaling pink)
  my-food ;;that student's food supply
  my-plan ;;how much they plan to take - overwrites if they move the take-this slider multiple times
  my-plan-% ;;how much they plan to take translated into percent
  my-list ;;storing how much food they took each round
  my-list-% ;;storing how big a percentage of the available food they took each round
  greedy? ;;true if they took more fish (absolute nrs) this round than last - overwrites every round
  greedy-%?
  humble?
  humble-%?
]

banners-own [banner-my-food] ;;@use this to update label

to startup
  ;;hubnet-reset ;;@REMOVE THIS LINE TO WORK WITH GBCC AND HEROKU IN BROWSER
  setup
end

to setup
  clear-patches
  ask banners [die] ask standins [die]
  clear-all-plots
  clear-output
  clear-drawing
  set current-function "Play first round to update" set current-prognosis "None yet"
  set greedy-list []
  set humble-list []
  set greedy-list-% []
  set humble-list-% []
  listen-clients ;;this creates the new students
  start-over ;;resets all global and student values + updates their view ;;also sets up patches
  reset-ticks
end

to go ;;this just ticks away, updating the view
  if food-supply <= 0 ;;IF THERE IS NO FOOD LEFT!
  [output-print ("GAME OVER. You're all out of food! :-(")
    ;;hubnet-broadcast-message (word "GAME OVER. You're all out of food! :-(") ;;REMOVING HUBNET-BROADCAST FOR GBCC?!
    stop]

  listen-clients ;;get commands and data from clients
  every 0.3 [
    ask patch 0 -1 [set plabel food-supply]
  ]

  ask banners [reposition] ;;updates the banners' labels with each client's food supply

tick-advance 1 ;;this doesn't update the plots
end


to play ;;this takes the food and advances! by the press of the button!
  check-if-ready ;;redundant coding?
  ifelse all-ready? [ ;;only plays the round if all students have chosen a legitimate amount to take

  set last-total-taken 0 ;;reset the value from last round
  set last-total-taken (sum [my-plan] of students) ;;how much the students take in total
  set all-time-taken (all-time-taken + last-total-taken)
  set food-supply (food-supply - last-total-taken) ;;update the food supply

  if food-supply > 0 ;;BEGINNING OF IF-LOOP
  [
  set turn (turn + 1)

  output-print "" output-print "NEW ROUND:"

  ask students [
      set my-list lput my-plan my-list ;;@adds an element to their list with how much they took this round
      set my-list-% lput my-plan-% my-list-%


      ifelse length my-list > 1[  ;;if not first round (for this student)

        ifelse((last my-list) > (last (but-last my-list))) ;;and if they took more fish this round than last round
        [set greedy? true set humble? false]
          [set greedy? false set humble? true]
        ]
        [set greedy? false set humble? false] ;;if first round for that student

       ;;@^^add the same for if they were percentage-greedy/humble (my-plan-% and my-list-%
       ifelse length my-list-% > 1[  ;;if not first round (for this student)
        ifelse((last my-list-%) > (last (but-last my-list-%))) ;;and if they took more fish this round than last round
        [set greedy-%? true set humble-%? false]
          [set greedy-%? false set humble-%? true]
        ]
        [set greedy? false set humble? false] ;;if first round for that student



      set color base-color
   ;;@ output-print (word "food: " my-food " , took: " my-plan) ;;to make non-anonymous: use output-show ;;USE THIS TO SHOW WHAT PEOPLE DID
      ;;output-show (word "Food: " my-food ". I took: " my-plan)
      if my-plan != "TOO GREEDY!" [ set my-food (my-food + my-plan)] ;;the if-statement is to get around "TOO GREEDY!"
      set my-plan 0 ;;resets/makes their plan 0 for next round
    ] ;;ASK STUDENTS ends here

    ;;CHANGE DUMMY LABELS BY ASKING THE BANNERS DIRECTLY
   ask banners [
      set banner-my-food [my-food] of one-of in-link-neighbors ;;shows label with their food
      set label word "Food: " banner-my-food
      ifelse [greedy? = true] of one-of in-link-neighbors
        [set label-color red]
        [set label-color white]

      if [humble? = true] of one-of in-link-neighbors
        [set label-color green]

    ]

   ;;MULTIPLY THE GOODS
  set food-supply floor (multiplier * food-supply) ;;floor rounds down to nearest integer) ;;could maybe make a more complicated formula? Or add randomness?

  output-print (word "There were " old-food-supply " fish.")
  output-print (word last-total-taken " fish were taken this round, leaving " (old-food-supply - last-total-taken) ".")
  output-print (word "After being multiplied by " multiplier ", now there are " food-supply " fish in total.")

  ;;THE GREEDY ONES
  set greedy-list [self] of students with [greedy? = true]
  ifelse (length greedy-list = 0)
      [output-print "Nobody was greedier and took more fish than they did last round!"]
      [output-print (word "These greedy players (with red labels) took more fish than they did last round: ") output-print greedy-list]

  set greedy-list-% [self] of students with [greedy-%? = true]

  ;;THE HUMBLE ONES
  set humble-list [self] of students with [humble? = true]
  ifelse (length humble-list = 0)
      [output-print "Nobody was more humble and took less fish than they did last round!"]
      [output-print (word "These humble players (with green labels) took less fish than they did last round: ") output-print humble-list]

  set humble-list-% [self] of students with [humble-%? = true]



  ;;update the function monitor (for the students to see mathematically what happened last round)
   set current-function (word "f(x)  =  " multiplier " * (" old-food-supply " - " last-total-taken ")  =  " food-supply)
   ;;@ set current-prognosis


    set old-food-supply2 old-food-supply ;;old-food-supply2 is used for prognosis! (at the end of play, it actually holds the initial/last round's food supply ;;@clumsy...
    set old-food-supply food-supply ;;puts the current food supply as the old food supply

    if count students > 0 [set max-take floor (food-supply / count students)] ;;the new proportion/max grab for everyone

  ask students [ ;;update the values on the clients' interfaces ;;@COULD SEND THEM MORE INFO ABOUT THE BEHAVIOR OF THE OTHERS?
    hubnet-send user-id "My food" my-food
    hubnet-send user-id "Turn nr" turn
    hubnet-send user-id "Food supply" food-supply
    hubnet-send user-id "My plan" my-plan
    hubnet-send user-id "Taking %" my-plan-%
    hubnet-send user-id "Function" current-function
    hubnet-send user-id "Max take" max-take
  ] ;;this works!!! any other things I want to update in their interface?

  ] ;;END OF IF-LOOP (if there is still food)
  set clear-prognosis? true
  update-plots

  ] ;;END of if all students are ready to eat
  [output-print "Not all students are ready to eat yet!"] ;;else - if not all students are ready
end

to start-over ;;reset global and student values
  set turn 0

  set n 0 ;;for the prognosis iteration
  set last-n 0
  set update-monitors? true ;;so we only say when we DON'T want them to update

  set last-total-taken 0
  set all-time-taken 0
  set food-supply food-at-start
  if count students > 0 [set max-take floor (food-supply / count students)]
  set old-food-supply food-supply
  set old-food-prog food-supply ;;for the prognosis and plot
  layout-patches ;;for where to place students visually + the middle food patch
  ask students [
    reset-student-food
    set color base-color
    set my-plan 0 set my-plan-% 0 ;;@?
    set my-list [] set my-list-% []
    set greedy? false
    set humble? false
    attach-banner "Food: 0"
  ] ;;this also updates all their monitors
  update-plots
end

to layout-patches
  ask invisibles1 [die] ask invisibles2 [die] ;;gets rid of any earlier ones
  create-invisibles1 10 create-invisibles2 10 ;;@or the nr of students participating
  layout-circle invisibles1 8 layout-circle invisibles2 13
  ask invisibles1 [hide-turtle] ask invisibles2 [hide-turtle] ;;they're invisible, but used for the good-patches
  set good-patches patches with [count invisibles1-here = 1 or count invisibles2-here = 1]
  ;;ask good-patches [set pcolor red] ;;@just to check what the good-patches look like if changing setup, purely aesthetic ;-)

  ;;the food in the middle:
  ask patch 0 0 [sprout-standins 1 [set color 56 set shape "fish" set size 1.5]] ;;just visual food ;)
  ask patch 0 -1 [set plabel-color white set plabel food-supply] ;;number representing the common food supply
  ask patches [ifelse (distancexy 0 0) < 2 = TRUE [set pcolor 103] [set pcolor black]] ;;a little cute lake ;;@make it less square and ugly?
end

to reset-student-food ;;student procedure, updates their view
  set my-food 0
  hubnet-send user-id "My food" 0 ;;sets it to 0 in the client view as well
  hubnet-send user-id "Food supply" food-at-start ;;update their view
  hubnet-send user-id "Turn nr" turn
  hubnet-send user-id "Function" current-function ;;giraf
  hubnet-send user-id "Max take" max-take
end

to check-if-ready
  ifelse all? students [color = gray] ;;ie. they have made a valid plan! ;;recode this more elegantly?
  [set all-ready? true] [set all-ready? false]
end


;;@ Ida working on this
to run-prognosis ;;prognosis for future food supply if multiplier and total-taken stay the same
  if n = 0 [
    output-print "" output-print "PROGNOSIS:"
    set clear-prognosis? true
    set update-monitors? false ;;so the other plots don't update!!!
    update-plots ;;just clears the prognosis plot
    set clear-prognosis? false ;;ready to plot the prognosis
    set old-food-prog old-food-supply2 ;;so the value is kept save in old-food-supply2, just in case the prognosis is run again on the same round
  ]
  let new-food-prog floor (multiplier * (old-food-prog - last-total-taken)) ;;floor rounds down, just as in the game ;;@PROBLEM?!

  set old-food-prog new-food-prog ;;for plotting! put f(x) in x's place for next iteration

  output-print (word "Round " n ": " old-food-prog " fish") ;;@REMOVE FROM OVERVIEW?

  update-plots ;;HOW DO I UPDATE ONLY THE PROGNOSIS PLOT?! @fixed! updated with old-food-prog!

  set last-n n ;;for the plot update condition, updates if n != last-n ;;@make this work???
  set n (n + 1) ;;(i.e. plot updates every iteration at this point!)

  if n = 50 or old-food-prog <= 0 [ ;;if we run out of food or if we're still looking good in n days
    ifelse old-food-prog <= 0
       [set death-day n] ;;when they will run out of food
       [set death-day "Sustainable"]

    ;;FOR THE OVERVIEW SUM-UP
    ifelse death-day = "Sustainable"
      [output-print "SUSTAINABLE! :-)" output-print (word "If you continue taking " (last-total-taken) " fish in total every round, you will have " old-food-prog " fish in 50 rounds.")]
      [output-print "UNSUSTAINABLE! :-(" output-print (word "If you continue taking " (last-total-taken) " fish every round, you will run out of fish in " death-day " rounds.")]


    set n 0 set last-n 0
    set old-food-prog old-food-supply2 ;;back to the value in this round, if they want to run the prognosis again
    set update-monitors? true ;;other plots back to being allowed to update
    stop
    ;;if new-food-prog <= 0 [stop]
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Code for HubNet and interacting with clients;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to listen-clients
  while [hubnet-message-waiting?] ;;as long as there are new messages in the cue from clients
  [
   hubnet-fetch-message ;;get the first message in the cue
   ifelse hubnet-enter-message? ;;if a new student has entered
    [create-new-student display] ;;create a new student
    [
      ifelse hubnet-exit-message? ;;if somebody leaves
      [remove-student display] ;;remove the one who left
      [execute-command hubnet-message-tag
      ] ;;hubnet-message-tag is the name of the interface element
  ]
 ]
end

to remove-student
  ask students with [user-id = hubnet-message-source] ;;if a student logs out, remove them
  [die]
end

to execute-command [command]
  if command = "take-this"
  [
    ask students with [user-id = hubnet-message-source] ;;the student who took this amount
    [
      ifelse limit-on = TRUE [
        ifelse hubnet-message <= max-take ;;the proportion students can maximally take
        [set my-plan hubnet-message ;;what they plan to take - if it's not too greedy!
         set my-plan-% precision ((my-plan / food-supply) * 100) 2 ;;the percentage with 2 decimal places
        ]
        [set my-plan "TOO GREEDY!"]
      ] ;;if limit on end bracket
      [set my-plan hubnet-message] ;;if limit-on is FALSE

    ]
  ]

  if command = "Ready to eat"
  [
    ask students with [user-id = hubnet-message-source]
     [
        if my-plan = "TOO GREEDY!" [set color base-color] ;;to catch those that might choose correctly, turn gray, but then choose greedily (and not just stay gray)...
        if my-plan != "TOO GREEDY!" and my-plan >= 0 [ ;;to make sure they didn't just click ready but didn't move the slider so my-plan didn't update ;;@could instead save old my-plan?
          set color gray ] ;;means they have decided
        hubnet-send user-id "My plan" my-plan ;;de kan se deres nuværende plan. først når der trykkes play, opdateres deres mad
        hubnet-send user-id "Taking %" my-plan-%
        ;;@set my-final-plan my-plan ;;is this clumsy programming? - make sure this change makes it automatically advance in 'play'?
    ]
  ]
end

to create-new-student
  create-students 1
  [
   setup-student-vars
    send-info-to-clients
  ]
end

to setup-student-vars ;;turtle procedure
  set user-id hubnet-message-source
  set my-name word self "" ;;makes it into a string
  set shape "person"
  set size 1.5
  set base-color one-of [14 17 24 27 45 54 66 75 85 95 104 114 117 124 127 134 137 9.9]
  set color base-color
  set label-color white
  set my-food 0
  set my-plan 0 ;;can change default
  set my-list []
  set my-list-% []
  set greedy? false
  ;;find a good visual position:
  let my-patch one-of good-patches with [not any? students-here]
  ifelse(my-patch != nobody)
    [move-to my-patch]
  [setxy random-xcor random-ycor]

  ;;attach the dummy breed for better label positioning:
  attach-banner "Food: 0" ;;clumsy coding right now - manually string sets it to 0 until my-food is updated in 'to play'
end

to attach-banner [x]
  hatch-banners 1 [
   set size 0
   set label x
   create-link-from myself [
     tie
     hide-link
    ]
  ]
end

to reposition ;;banner procedure
  ifelse count in-link-neighbors > 0 [ ;;prevents it from crashing when a client exits
  move-to one-of in-link-neighbors ;;@use this link call to set the label to that student's food supply!

  let banner-angle 142 ;;@can change this
  let banner-distance 2.20

  set heading banner-angle
  forward banner-distance
  ]
  [die] ;;if their neighbor/client has left
end

to send-info-to-clients ;;turtle procedure
  hubnet-send user-id "My food" my-food
  hubnet-send user-id "Food supply" food-supply
  hubnet-send user-id "Turn nr" turn
  hubnet-send user-id "Function" current-function
  hubnet-send user-id "Me" my-name
  hubnet-send user-id "Max take" max-take
  ;;if limit-on?
  ;;food-supply / count students ;;allowed to take this
end
@#$#@#$#@
GRAPHICS-WINDOW
270
10
802
543
-1
-1
15.9
1
12
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

SLIDER
20
20
235
53
food-at-start
food-at-start
1
300
104.0
1
1
NIL
HORIZONTAL

MONITOR
11
155
68
200
Turn
turn
17
1
11

BUTTON
96
60
159
93
NIL
Go
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
31
60
95
93
Setup
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
161
60
224
93
NIL
Play
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
78
155
158
200
Food supply
food-supply
17
1
11

MONITOR
166
155
254
200
Last food eaten
last-total-taken
17
1
11

MONITOR
166
206
254
251
All time eaten
all-time-taken
17
1
11

OUTPUT
815
45
1485
227
11

TEXTBOX
1110
25
1257
43
OVERVIEW
14
0.0
1

SLIDER
21
100
230
133
multiplier
multiplier
1
5
1.1
.1
1
NIL
HORIZONTAL

MONITOR
1020
280
1232
325
Function
current-function
17
1
11

TEXTBOX
933
239
1320
290
                                  THE  FUNCTION\nnew-food-supply = multiplier * (old-food-supply - total-taken)
14
0.0
1

SWITCH
24
217
127
250
limit-on
limit-on
0
1
-1000

TEXTBOX
12
255
162
283
If on: students can only take 'their proportion' of the food
11
0.0
1

PLOT
815
395
1015
545
Food supply
Time
Food
0.0
10.0
0.0
10.0
true
false
"" "if update-monitors? = false [stop]"
PENS
"default" 1.0 0 -13345367 true "" "plot food-supply"

PLOT
1025
395
1225
545
Humble players
Time
Count
0.0
10.0
0.0
10.0
true
false
"" "if update-monitors? = false [stop]"
PENS
"pen-1" 1.0 0 -14439633 true "" "plot length humble-list"

PLOT
1230
395
1430
545
Greedy players
Time
Count
0.0
10.0
0.0
10.0
true
false
"" "if update-monitors? = false [stop]"
PENS
"default" 1.0 0 -8053223 true "" "plot length greedy-list"

MONITOR
5
290
175
335
NIL
current-prognosis
17
1
11

BUTTON
85
340
192
373
NIL
run-prognosis\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
25
375
250
535
50-turn prognosis
Time
Food
0.0
50.0
0.0
10.0
true
false
"" "if clear-prognosis? = true [clear-plot]"
PENS
"food" 1.0 0 -955883 true "" "plot old-food-prog"
"zero" 1.0 0 -10873583 true "" "plot 0"

MONITOR
180
290
255
335
NIL
death-day
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
MONITOR
110
220
174
269
My food
NIL
3
1

SLIDER
16
121
188
154
take-this
take-this
0.0
30.0
0
1.0
1
NIL
HORIZONTAL

MONITOR
25
220
105
269
Food supply
NIL
3
1

MONITOR
75
280
132
329
Turn nr
NIL
3
1

MONITOR
90
65
176
114
My plan
NIL
3
1

BUTTON
50
164
154
197
Ready to eat
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
756
133
1186
177
                                  THE  FUNCTION\nnew-food-supply = multiplier * (old-food-supply - total-taken)
14
0.0
1

MONITOR
805
177
1095
226
Function
NIL
3
1

VIEW
215
11
740
536
0
0
0
1
1
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

MONITOR
45
340
165
389
Me
NIL
3
1

MONITOR
60
10
122
59
Max take
NIL
0
1

MONITOR
25
65
87
114
Taking %
NIL
3
1

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
