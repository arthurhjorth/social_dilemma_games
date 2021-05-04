;;;;;;;;;;;;;;;;;;;
;;;;WASTE MODEL;;;;
;;;;;;;;;;;;;;;;;;;

globals [

  type-waste-type ;;@@@ used to be an interface input

  ;;for grouped comparison bar plot:
  y.b


  waste-list
  co2-list
  weekly-co2 ;;for calculate

  new-per-week
  future-per-year
  now-per-year
  ydata-2-plot
  plot-item-count ;;item 0 waste-pair (for future plot)
  max-y ;;@



  horizon-line ;;visuals
]

breed [props prop] ;;decorative turtles without other function
breed [bottles bottle]

patches-own [display-here?]



to setup
  clear-all
  make-world
  set type-waste-type "" ;;@@@used to be an interface input
  set waste-list [] set co2-list []
end


to-report waste-type
  ifelse choose-waste-type != "(type custom waste)"
  [
    report choose-waste-type
  ]
  [
    ifelse type-waste-type != "" [
      report type-waste-type
    ]
    [
      report "TYPE OR CHOOSE WASTE TYPE"
    ]
  ]
end


to add-waste
  let new-item (list waste-nr waste-type) ;;what they want to add, e.g. [4 "plastic bottles"]

  ifelse member? (item 1 new-item) map last waste-list [
    ;;if the item (plastic type) is already in waste-list, overwrite it with the new amount:
    let index position (item 1 new-item) map last waste-list

    ifelse item 0 new-item = 0 [
      ;;if it was changed to 0:
      set waste-list remove-item index waste-list
      show-waste-list
    ]
    [ ;;if something else than 0:
      set waste-list replace-item index waste-list new-item
      show-waste-list
    ]

  ]
  [ ;;otherwise, just add it (@maybe add, as long as the amount isn't 0):
    set waste-list fput (list waste-nr waste-type) waste-list
    show-waste-list
  ]




end


to show-waste-list ;;so they can go back in the output to see their overview (@+ maybe add any easy way to make small changes to it???)
  clear-output

  ifelse length waste-list != 0 [
    foreach waste-list [
      [waste-pair] ->
      output-print ( word (item 0 waste-pair) " " (item 1 waste-pair) )
    ]
  ]
  [ ;;if waste-list is still empty:
    output-print "You haven't added anything to your weekly waste yet!"
  ]



end


to calculate ;;after they've added all their waste
  clear-output ;;so they don't see their weekly list anymore (but it's saved in waste-list)
  ;;set-current-plot "Prognosis"
  ;;clear-plot

;;AMOUNT
  if calculate-this = "amount" [
    output-print "In one year, you'll have used:"

    foreach waste-list [
      [waste-pair] ->
      output-print (word (item 0 waste-pair * 52) " " (item 1 waste-pair)  )
    ]

    output-print ""
    output-print "In 50 years, you'll have used:"

    foreach waste-list [
      [waste-pair] ->
      output-print (word (item 0 waste-pair * 2607) " " (item 1 waste-pair)  ) ;;item 0 is the nr, item 1 is the type
    ]

     ;;prediction/if change:
    output-print ""
    output-print "But if you used just ONE less of each thing every week...:"
    output-print "You would save:"
    foreach waste-list [
      [waste-pair] ->
       let saved-in-year (item 0 waste-pair * 52) - ( (item 0 waste-pair - 1) * 52)
       let saved-in-50-years (item 0 waste-pair * 2607) - ( (item 0 waste-pair - 1) * 2607)
       output-print (word saved-in-year " " (item 1 waste-pair) " after one year")
       output-print (word saved-in-50-years " " (item 1 waste-pair) " after 50 years")
    ]
  ]

;;plotting:
  ;;plot the current trajectories for each waste type (amount):
;  foreach waste-list [
;    [waste-pair] ->
;
;    let clean-name (item 1 waste-pair)
;
;    ;;this doesn't seem to work in NetLogo Web (and not needed if I remove the () from the choosed drop-down:
;    ;;let almost-clean-name remove "(" (item 1 waste-pair)
;    ;;let clean-name remove ")" almost-clean-name ;;without parantheses
;
;    let length-name length clean-name ;;(substring starts at 0, but doesn't include the last number - so this works)
;    let waste-name substring clean-name 8 length-name ;;removes the 'plastic ' (8 characters) from the waste name (for more plot space ;-))
;    set-current-plot-pen (word waste-name " (current)")
;
;    foreach (range 1 53) [ ;;the x axis of the plot now shows 0-52 weeks
;      [nr-of-weeks] ->
;
;        plotxy nr-of-weeks (nr-of-weeks * (item 0 waste-pair))
;    ]
;
;
;  ]

  ;;plot prognosis trajectories if they use ONE less every week for each waste type (amount):
;    foreach waste-list [
;    [waste-pair] ->
;
;    let clean-name (item 1 waste-pair)
;    ;;let almost-clean-name remove "(" (item 1 waste-pair)
;    ;;let clean-name remove ")" almost-clean-name ;;without parantheses
;
;    let length-name length clean-name ;;(substring starts at 0, but doesn't include the last number - so this works)
;    let waste-name substring clean-name 8 length-name ;;removes the 'plastic ' (8 characters) from the waste name (for more plot space ;-))
;    set-current-plot-pen (word waste-name " (change)")
;
;    foreach (range 1 53) [
;      [nr-of-weeks] ->
;      plotxy nr-of-weeks (nr-of-weeks * ( ( item 0 waste-pair) - 1))
;    ]
;  ]

;;CO2 POLLUTION
  if calculate-this = "CO2 pollution" [
    output-print "This is your weekly CO2 pollution:"
    output-print ""

    ;;@idea: could sort this list in increasing/decreasing order!

    foreach waste-list [
      [waste-pair] ->
      let co2-amount item 0 waste-pair * (one-of (range 0.5 25 0.5) ) ;;@completely random and fake now - add DATA!
      set co2-list fput co2-amount co2-list
      set weekly-co2 precision (sum co2-list) 2
      output-print  ( word (item 0 waste-pair) " " (item 1 waste-pair) ": " precision co2-amount 2 " grams of CO2" )
    ]

    output-print ""
    output-print (word "Total weekly CO2 pollution: " weekly-co2 " grams of CO2")
    output-print "(right now this calculation is completely random!)"

    ;;prediction/if change: @change for CO2 levels
    output-print ""
    output-print "But if you used just ONE less of each thing every week...:"
    output-print "You would save:"
    output-print "(*add data for how much CO2 that would save for"
    output-print " each waste type)"

    ]

  ;;KILOS
  if calculate-this = "kilos" [
    output-print "This is how much your plastic waste weighs:"
    output-print "In one week: x kg"
    output-print "In one year: x kg"
    output-print "In 50 years: x kg"

  ]

end


to compare-pollution ;;when they press the button, create/refresh the grouped bar plot!
  set-current-plot "Plastic Pollution"
  clear-plot

  ;;@make data dynamic:
  let y.a [44 78 42 40] ;;red bars (you)

  if country = "Denmark" [ ;;this should be actually dynamic, linked up to a database or something
    set y.b [49 63 27 32] ;;grey bars (your country)
  ]
  if country = "Djibouti"
  [
    set y.b [22 44 11 19]
  ]


  let y.c [33 29 24 31] ;;blue bars (the world)
  let y.d [54 35 46 12] ;;green bars (sustainable)
  let plotname "Plastic Pollution"
  let ydata (list y.a y.b y.c y.d)
  let pencols (list 16 grey blue 56) ;;colors of bars
  let pennames (list "You" "Your country" "The world" "Sustainable")
  let barwidth 1
  let step 0.01
  groupedbarplot plotname ydata pencols pennames barwidth step  ;;call the plotting procedure
end


to groupedbarplot [plotname ydata pencols pennames barwidth step]
  ;; Get n from ydata -> number of groups (colors)
  let n length ydata
  let i 0
  ;; Loop over ydata groups (colors)
  while [i < n]
  [
    ;; Select the current ydata list and compute x-values depending on number of groups (n), current group (i) and bardwith
    let y item i ydata
    let x n-values (length y) [? -> (i * barwidth) + (? * (((n + 1) * barwidth)))]
    ;;print y
    ;;print x

    ;; Initialize the plot (create a pen, set the color, set to bar mode and set plot-pen interval)
    set-current-plot plotname
    create-temporary-plot-pen item i pennames ;;(word i) ;;changed from 'word i' in the paranthesis@@@
    set-plot-pen-color item i pencols
    set-plot-pen-mode 1 ;;bar mode
    set-plot-pen-interval step

    ;; Loop over xy values from the two lists:
    let j 0
    while [j < length x]
    [
      ;; Select current item from x and y and set x.max for current bar, depending on barwidth
      let x.temp item j x
      let x.max x.temp + (barwidth * 0.97)
      let y.temp item j y

      ;; Loop over x-> xmax and plot repeatedly with increasing x.temp to create a filled barplot
      while [x.temp < x.max]
      [
        plotxy x.temp y.temp
        set x.temp (x.temp + step)
      ] ;; End of x->xmax loop
      set j (j + 1)
    ] ;; End of dataloop for current group (i)
    set i (i + 1)
  ] ;; End of loop over all groups
end



to barplot [plotname ydata pencols pennames barwidth step] ;;@not working yet!
  ;;@tweak the groupedbarplot procedure to make a function for a pretty non-grouped barplot!
  ;; Get n from ydata -> number of groups (colors)
  let n length ydata
  let i 0

  set-current-plot plotname ;;@
  clear-plot ;;@
  ;;let new-per-week ( (item 0 waste-pair) + change-per-week ) ;;new-per-week is new nr of items used per week (change-per-week is the interface slider)
  set max-y ((plot-item-count + 5) * 52) + 10 ;;right now +5 is the max change in the interface slider. +10 for some aesthetic space above the bar
  set-plot-y-range 0 max-y  ;;@

  ;; Loop over ydata groups (colors)
  while [i < n]
  [
    ;; Select the current ydata list and compute x-values depending on number of groups (n), current group (i) and bardwith
    let y item i ydata
    let x n-values (length y) [? -> (i * barwidth) + (? * (((n + 1) * barwidth)))]
    ;;print y
    ;;print x

    ;; Initialize the plot (create a pen, set the color, set to bar mode and set plot-pen interval)
    set-current-plot plotname
    create-temporary-plot-pen item i pennames ;;(word i) ;;changed from 'word i' in the paranthesis@@@
    ;;set-plot-pen-color item i pencols
    set-plot-pen-mode 1 ;;bar mode
    set-plot-pen-interval step

    ;; Loop over xy values from the two lists:
    let j 0
    while [j < length x]
    [
      ;; Select current item from x and y and set x.max for current bar, depending on barwidth
      let x.temp item j x
      let x.max x.temp + (barwidth * 0.97)
      let y.temp item j y

      set-plot-pen-color item j pencols ;;@

      ;; Loop over x-> xmax and plot repeatedly with increasing x.temp to create a filled barplot
      while [x.temp < x.max]
      [
        plotxy x.temp y.temp
        set x.temp (x.temp + step)
      ] ;; End of x->xmax loop
      set j (j + 1)
    ] ;; End of dataloop for current group (i)
    set i (i + 1)
  ] ;; End of loop over all groups
end


;;DYNAMIC FUTURE PLOT:

to plot-the-future
  ;;@right now loops over waste list, but should probably be able to choose just one item at a time
  if length waste-list != 0 [

    every 0.1 [

      ;;1. THE LINE PLOT

      set-current-plot "The future"

      ;;plot the current trajectories for the chosen waste type (amount):

      ifelse not member? choose-item map last waste-list [
        ;;if the chosen item is not in waste-list:
        clear-output
        output-print "The chosen item is not currently in your waste list!"
        output-print "Add it or choose another one."
        output-print "(click 'Show my waste list' below to see it)"
        stop ;;stops the plot-the-future forever button

      ]
      [ ;;if choose-item IS in waste-list, now we can plot all sorts of stuff:

        ;;get the weekly amount from waste-list:
        let index position choose-item map last waste-list ;;the position of the item in waste-list
        let the-entry (item index waste-list)
        let waste-amount item 0 the-entry


        ;;clean the name for the plots:
        let length-name length choose-item ;;(substring starts at 0, but doesn't include the last number - so this works)
        let waste-name substring choose-item 8 length-name ;;removes the 'plastic ' (8 characters) from the waste name (for more plot space ;-))



        ;;plot current use:
        create-temporary-plot-pen  (word waste-name " (now)") ;;create a plot pen with that waste name
        set-current-plot-pen (word waste-name " (now)")
        set-plot-pen-color black
        plot-pen-reset ;;clears anything it has drawn before

        foreach (range 1 53) [ ;;the x axis of the plot now shows 0-52 weeks
          [nr-of-weeks] ->

          plotxy nr-of-weeks (nr-of-weeks * waste-amount)
        ]

        set now-per-year 52 * waste-amount

        ;;plot trajectory based on the slider (this should change in real time):
        create-temporary-plot-pen  (word waste-name " (change)") ;;create a plot pen with that waste name
        set-current-plot-pen (word waste-name " (change)")
        set-plot-pen-color blue
        plot-pen-reset ;;clears anything it has drawn before

        set new-per-week ( waste-amount + change-per-week ) ;;new nr of items used per week (change-per-week is the interface slider)
        set plot-item-count waste-amount ;;for the barplot procedure

        foreach (range 1 53) [ ;;the x axis of the plot now shows 0-52 weeks
          [nr-of-weeks] ->

          ifelse new-per-week > 0 [
            plotxy nr-of-weeks (nr-of-weeks * new-per-week)
            set future-per-year 52 * new-per-week
          ]
          [ ;;if it gets to 0 (or less) per week with the change:
            plotxy nr-of-weeks 0
            set future-per-year 0
          ]
        ] ;;end of plotting loop


        ;;2. THE BAR PLOT

        ;;try with the procedure:

        let plotname "Bar future"
        let your-country 210 let sustainable 100 ;;@random static numbers now

        let y-nest [[]]
        let ydata-2 (list now-per-year future-per-year 210 100)
        set ydata-2-plot lput ydata-2 item 0 y-nest
        let pencols (list black blue grey green) ;;colors of bars
        let pennames (list "You now" "You with change" "Your country" "Sustainable")
        let barwidth 1.2
        let step 0.01

        barplot plotname ydata-2-plot pencols pennames barwidth step  ;;call the plotting procedure


      ] ;;end of if choose-item is in waste-list

    ] ;;end of if length waste-list != 0


    ;;VISUALIZE (right now only if bottles):






  ] ;;end of every 0.x


end

to-report new-per-week-str ;;for explanatory monitor with the future plots
  ;;ifelse ;;@could add 'cut down' vs 'scaled up'

  report (word "This is what a year would look like if you instead used " new-per-week " " choose-item " per week:")
end




;;---OLD STUFF:


to-report bottles-in-year
  report bottles-in-week * 52
end

;;INTERFACE - DON'T NEED THIS...
to make-world
  ;;ocean and sky background:
  set horizon-line (max-pycor - 35)

  ask patches with [pycor < horizon-line] [
   set pcolor scale-color 105 ((random 500) + 5000) 0 9000  ;;ocean
  ]
  ask patches with [pycor > horizon-line] [
   set pcolor scale-color 96 ((random 500) + 5000) 0 9000 ;;sky
  ]
  ask patches with [pycor = horizon-line] [
   set pcolor scale-color 104 ((random 500) + 3000) 0 6500 ;;horizon line
  ]

  ;;sun:
  ask patch (min-pxcor + 15) (max-pycor - 10) [
    sprout-props 1 [ ;;outline
      set shape "sun" set color 44 set size 15
    ]
    sprout-props 1 [ ;;fill-in
      set shape "sun" set color 47 set size 13
    ]
  ]

  ;;birds in sky:
  create-props 1 [
    set shape "bird-v" set color black set size 9 setxy 79 90 set heading 14
  ]
  create-props 1 [
    set shape "bird-v" set color black set size 8 setxy 86 93 set heading 25
  ]
  create-props 1 [
    set shape "bird-v" set color black set size 11 setxy 88 85 set heading 20
  ]

  ;;cute little sea turtle family:
  create-props 1 [
    set shape "turtle" set color 62 set size 10 setxy (min-pxcor + 15) (min-pycor + 15) set heading 47
  ]
end

to visualize
  ask bottles [die] ;;kill the previous bottles
  ask patches [set display-here? false]

  if visualize-this = "Bottles in a year" [
    ;;make list with the proper patch coordinates! loop through it? ask those patches to sprout bottles - but only the nr of patches as 'bottles-in-year'!

    ask patches with [(remainder pxcor 10 = 0) and (remainder pycor 10 = 0) and (pycor < horizon-line) and (abs pxcor <= 90) and (abs pycor <= 90)] [ ;;a max of 304
      set display-here? true ;;set pcolor black
    ]

    ask n-of bottles-in-year patches with [display-here? = true] [ ;;now randomised patches, could make it start from left to right
      sprout-bottles 1 [
        set shape "my-bottle" set color white set size 5
      ]
    ]
  ]


  if visualize-this = "Bottles in 50 years" [
    ask patches with [(remainder pxcor 2 = 0) and (remainder pycor 2 = 0) and (pycor < horizon-line)] [ ;;a max of 8383 (add more patches! ...)
      set display-here? true
    ]

    ask n-of (bottles-in-year * 50) patches with [display-here? = true] [
      sprout-bottles 1 [
        set shape "my-bottle" set color white set size 1
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1160
10
1503
354
-1
-1
1.67
1
10
1
1
1
0
0
0
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
225
55
310
95
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

TEXTBOX
45
10
395
51
What is YOUR impact on plastic pollution?
18
0.0
1

BUTTON
1035
115
1157
148
VISUALIZE!
visualize
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
1005
70
1155
115
visualize-this
visualize-this
"Bottles in a year" "Bottles in 50 years"
0

OUTPUT
5
310
450
560
11

INPUTBOX
25
210
80
270
waste-nr
7.0
1
0
Number

CHOOSER
25
130
180
175
choose-waste-type
choose-waste-type
"plastic bottles" "plastic bags" "plastic packages" "plastic cutlery" "plastic straws"
1

MONITOR
85
220
285
265
NIL
waste-type
17
1
11

BUTTON
290
220
377
265
Add waste
add-waste
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
1145
390
1510
535
Plastic Pollution
Ocean    Landfills      Recycled       Other         
unit?
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

TEXTBOX
1170
370
1445
388
Choose a country and compare pollution levels:
13
0.0
1

BUTTON
1285
540
1387
581
Compare!
compare-pollution
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
1145
540
1283
585
country
country
"Denmark" "Djibouti"
0

TEXTBOX
10
110
235
136
1. Choose a type of plastic:
14
0.0
1

TEXTBOX
10
190
425
221
2. Select the amount you use in ONE WEEK and press 'Add waste':
14
0.0
1

TEXTBOX
10
285
455
316
3. Keep going until you have an overview of your weekly plastic waste:
14
0.0
1

TEXTBOX
475
15
825
81
4. Choose what impact you want to learn about and press CALCULATE to see your results in the output box.
14
0.0
1

BUTTON
600
55
740
100
CALCULATE!
calculate
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
475
55
595
100
calculate-this
calculate-this
"amount" "CO2 pollution" "kilos" "(other things)" "(water? oil?" "(biodiversity?)"
1

TEXTBOX
1150
585
1300
603
(non-dynamic data right now)
11
0.0
1

BUTTON
5
563
145
598
Show my waste list
show-waste-list
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
1075
10
1155
70
bottles-in-week
2.0
1
0
Number

SLIDER
605
185
860
218
change-per-week
change-per-week
-5
5
-1.0
1
1
NIL
HORIZONTAL

TEXTBOX
10
55
225
91
0. Press the setup button to start up the model:
14
0.0
1

TEXTBOX
585
470
1110
570
New things:\n- now easier to change weekly plastic waste at a later point than initial input (workflow)\n\n- new dynamic live plots for future predictions (step 5)
15
13.0
1

PLOT
475
270
835
455
The future
Time (one year)
Amount
0.0
52.0
0.0
10.0
true
true
"" ""
PENS

BUTTON
475
230
600
263
NIL
plot-the-future
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
755
380
830
425
With change:
future-per-year
17
1
11

MONITOR
755
335
830
380
Now:
now-per-year
17
1
11

TEXTBOX
475
125
800
191
5. What if you changed your weekly plastic use? Choose an item and move the slider to see your impact for one year with and without the change:
14
0.0
1

PLOT
840
270
1120
455
Bar future
Now       Change        Country    Sustainable  
Amount
0.0
10.0
0.0
10.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

CHOOSER
475
185
600
230
choose-item
choose-item
"plastic bottles" "plastic bags" "plastic packages" "plastic cutlery" "plastic straws"
0

MONITOR
605
220
1025
265
NIL
new-per-week-str
17
1
11

TEXTBOX
160
565
470
600
<--- You can always click this button to see your weekly plastic waste, and change or edit it above
13
0.0
1

TEXTBOX
255
150
405
168
OUNCE OR GRAM SELECTOR
11
0.0
1

TEXTBOX
375
110
525
136
think hacky: how to change text (numbers)
11
0.0
1

TEXTBOX
920
185
1070
211
maybe think non-linear reduction strategies
11
0.0
1

TEXTBOX
235
125
385
151
select S, M or L (or input exact weight)
11
0.0
1

TEXTBOX
855
95
1005
113
focus on water and CO2
11
0.0
1

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

bird-v
true
0
Polygon -7500403 true true 149 150 149 135 163 116 180 100 196 93 214 93 227 96 237 102 248 111 253 119 256 128 253 147 248 134 248 135 245 127 242 120 237 115 230 111 223 108 211 104 199 108 189 116 178 123 167 133 158 142
Polygon -7500403 true true 151 150 151 135 137 116 120 100 104 93 86 93 73 96 63 102 52 111 47 119 44 128 47 147 52 134 52 135 55 127 58 120 63 115 70 111 77 108 89 104 101 108 111 116 122 123 133 133 142 142

bottle
false
0
Circle -7500403 true true 90 240 60
Rectangle -1 true false 135 8 165 31
Line -7500403 true 123 30 175 30
Circle -7500403 true true 150 240 60
Rectangle -7500403 true true 90 105 210 270
Rectangle -7500403 true true 120 270 180 300
Circle -7500403 true true 90 45 120
Rectangle -7500403 true true 135 27 165 51

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

my-bottle
false
0
Circle -7500403 true true 90 240 60
Rectangle -1 true false 135 8 165 31
Circle -7500403 true true 150 240 60
Rectangle -7500403 true true 90 105 210 270
Rectangle -7500403 true true 120 270 180 300
Circle -7500403 true true 90 45 120
Rectangle -7500403 true true 135 27 165 51

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

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

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
