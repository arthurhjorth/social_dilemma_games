globals [
  action ;;last button pressed. left = 1, right = 2
  ;;object-x ;;the object's current position
  ;;object-y
  push-force
  push-force-plot
  net-force
  total-push-force
  global-speed ;;for plotting @?
  choose-mass ;;objektets masse

  current-vælg-masse ;til opgave 2
  skub
  current-skub ;;til undersøg skubbekraft (opg 5)
  currently-vinter?
  my-colors ;;custom palette for plot line colors in "Fri leg"
  color-counter ;;for plot line colors in "Fri leg"

  fratræk-friktion?

  win? ;;to see if they've won
  lost? ;;to see if they've lost (pushed the object over the edge)

  score
  last-score ;;for coding purposes, keeping track of the previous score (to see if it's changed)
  season
  timer-running?
  vis-vektorer? ;;@gør til interface-kontakt

  timer-at-end ;;timer at time of win/deaths

  current-opgave
  current-object
  nr-of-pushes
  distance-flyttet
  plot-color ;;the color of the output graph for the current settings (object, skubbekraft, etc)

  house-color-time ;;for check-win, color house green if on the right patch, keep it green for a while

  mouse-was-down?
  mouse-dist ;;distance from mouse-down point to object
  mouse-acc
  old-mouse-x ;;keeping track of whether the mouse has been moved
  old-object-x ;;keeping track for mgraphics (mouse) purposes
  update-mgraphics?
  mouse-divisor
  mouse-on-object?
  mouse-pull-on?

  try-nr ;;@not used now? ;;a nr starting at 0, goes up after each fail/win, used to name the list of saved values after each try
  save-list ;;the list storing saved values after each go

  patch-i-meter
  tick-i-sekunder

  gnidnings-kof ;;gnidningskoefficienten (hvis sommer)
  g ;;tyngdeaccelerationen

  a ;;acceleration
  v ;;velocity
  delta-v ;;change in speed. acceleration or deceleration
  delta-v-plot ;;for plotting, isn't set to 0 if it doesn't overcome the friction

  delta-x ;;displacement in meters

  friktion ;;friktion
  s ;;displacement
  u ;;initial/current speed
  final-displacement ;;after scaling

  ; JB - Track each `Genstart` to give a unique plot name
  genstart-number

]

breed [houses house] ;;needs to be a breed only so it can be in the background layer
breed [objects object]
breed [explosions explosion]
breed [players player]
breed [graphics graphic] ;;sparks
breed [mgraphics mgraphic] ;;mouse-related graphics
breed [vgraphics vgraphic] ;;vector force graphics

objects-own [
  object-name
  speed
  old-speed
  mass
  top-speed
  top-acc

  ;;kinetisk-energi

  real-heading
  apparent-heading ;;only for fail animation
]

graphics-own [lifetime name]
mgraphics-own [lifetime name]
vgraphics-own [vector-name]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;KRÆFTER OG BEVÆGELSE;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set save-list []

  ifelse vinter? [set currently-vinter? true] [set currently-vinter? false]
  set current-opgave opgave
  set current-object objekt ;;gem fra chooseren til global variabel, så det ikke ændres, hvis de ændrer det
  make-world ;;cliff and season also specified here
  make-object ;;sets up the chosen level that's chosen

  ;;set object-x -26 ;;the object's starting position

  set win? false set lost? false set fratræk-friktion? false
  set timer-running? false
  set vis-vektorer? false ;;@gør til interface-kontakt
  set nr-of-pushes 0
  set distance-flyttet 0
  set mouse-was-down? FALSE
  set patch-i-meter 1 ;;@kan tweakes ;;før: 0.75
  set tick-i-sekunder 0.1 ;;@kan tweakes
  set gnidnings-kof 0.36 ;;my = ca 0.36 for gummi mod græs (ingen enhed) (applied in friction calculations if season = summer)
  set g 9.82 ;;tyngdeaccelerationen på jorden. Enhed: m/s

  setup-plot ;;creates plot pens depending on the chosen opgave
  vis-instruks ;output-print startbesked i outputtet i interface

  reset-ticks
end

to go
  every 3 / hastighed   [

    ;;if count objects > 0 [ ;;NOW TWO REPORTERS INSTEAD? ;;but check that mouse-stuff works
      ;;set object-x [xcor] of one-of objects
      ;;set object-y [ycor] of one-of objects] ;;there'll always only be one object at a time

    if not lost? and not win? [do-mouse-stuff]

    move-person
    if not lost? [check-object] ;;to see if they've failed
    if lost? [fail-animation] ;;animation of object falling down

    if not lost? and not win? [
      accelerate-object
      check-win
      update-graphics
    ]

    update-plot ;;updates the plot with the custom temporary plot pens
    tick
  ]
end

to-report object-x
  if count objects > 0 [
      report [xcor] of one-of objects
  ]
end

to-report object-y
  if count objects > 0 [
      report [ycor] of one-of objects
  ]
end


to do-mouse-stuff
  if styring = "mus" [

  if not lost? and not win? and (old-mouse-x != mouse-xcor or old-object-x != object-x)
    [ ask mgraphics [die] set update-mgraphics? TRUE ] ;;update visuals only if mouse or object position has changed

  if update-mgraphics? [

      if [distance one-of objects <= 1] of patch (mouse-xcor) (mouse-ycor) [ ;;if the mouse is (roughly) on the object
        set mouse-pull-on? TRUE ;;this remains true until the mouse button is lifted (see next if-statement)
        ]

      if [distance one-of objects > 1] of patch (mouse-xcor) (mouse-ycor) and not mouse-down? [ ;;if mouse is not on object AND mouse button isn't pressed
        set mouse-pull-on? FALSE
      ]


  if mouse-down? and mouse-pull-on? [ ;;if the mouse is pressed down while on the object, start the elastic!
    if not timer-running? [reset-timer] ;;if it's the very first push, start the timer
    set timer-running? TRUE

    create-mgraphics 1 [
      set size 1
      set color yellow
      set shape "circle"
      setxy (mouse-xcor) (object-y)
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

  if mouse-down? and abs mouse-dist > 0 [ ;;to avoid division by 0

    ;;ADD THE ACCELERATION VECTOR BASED ON THE DISTANCE
    let scaling-mouse 1000 ;;@ testing size of scaling-mouse
    set mouse-divisor scaling-mouse / mouse-dist ;;/ scaling-mouse

    set mouse-acc (- (mouse-dist)^ 2 ) / mouse-divisor ;;proportionel med kvadratet på afstanden ;;(og så lineært skaleret ned)
    set mouse-acc vælg-kraft / 10 * (- (mouse-dist)^ 2 ) / mouse-divisor ;;proportionel med kvadratet på afstanden ;;(og så lineært skaleret ned)

    if mouse-xcor > object-x [set mouse-acc (mouse-acc)] ;;if pushing left, subtract push-force instead of adding it (negative speed = left)
    if mouse-xcor < object-x [set mouse-acc (- mouse-acc)]
  ]

  set push-force mouse-acc ;;push-force is used in accelerate-object

  set old-mouse-x mouse-xcor ;;to check next run through if mouse position has changed
  set old-object-x object-x

  ] ;;END of if styring = mus
end


to accelerate-object
  ask objects [

;;0. Calculate friction FIRST?!
    ifelse season = "sommer"
      [set friktion ((gnidnings-kof * normalkraft) * tick-i-sekunder)] ;;friktion = my * normalkraft ;;enhed: Newton ;;ganget med tid, så det passer med skubbevektoren (?!) ;;altid positiv ;;@add precision?
      [set friktion 0]  ;;ingen friktion hvis vinter
                      ;;[set friktion precision ((0.05 * normalkraft) * tick-i-sekunder) 2] ;;@ lille gnidningskraft hvis is?
    ;;simulationen ignorerer den minimale forskel på statisk og dynamisk friktion


;;0.5. Calculate skubbekraft (scaled ligesom friktion?)
    ;;push-force = værdien for "skub". Positiv hvis mod højre, negativ hvis mod venstre.
    ;;enhed: Newton
       ;;MEN PER HVAD?! SEKUND? SKAL PASSE MED TICK-I-SEKUNDER! OG MED FRIKTIONEN!
    ;;SCALE PUSH-FORCE?!
    ;;@CHECK THAT PUSH-FORCE (SKUB) IS IN NEWTON - should it be 'translated' from the interface input number?! depending on tick-i-sekunder?



;;BEREGN NET-KRAFTEN (TRÆK FRIKTION FRA (/LÆG TIL)!
    ifelse abs push-force > friktion [ ;;hvis skubbekraften overstiger friktionskraften (@men hvis allerede i bevægelse, er det ikke nødvendigt)
      if push-force > 0 [
        set net-force (push-force - friktion) ;;if push towards right, friction towards left
      ]

      if push-force < 0 [
        set net-force (push-force + friktion) ;;if push towards left, friction towards right
      ]  ;;@MEN hvad hvis objektet fx bevæger sig med høj fart mod højre, men spilleren skubber et lille skub mod venstre? 2 x friktion?!
    ]

    [ ;;hvis skubbekraften IKKE overstiger friktionskraften (eller fx bare er 0):
      ifelse abs v > 0 ;;hvis objektet er i bevægelse:
        [
          set fratræk-friktion? TRUE

          ifelse v > 0
            [set net-force ( - friktion )] ;;hvis bevægelse mod højre
            [set net-force friktion] ;;hvis bevægelse mod venstre
          ;;så hvis der ikke skubbes (push-force = 0), trækkes friktionen stadig fra i net-force! men kun ned til v = 0! kommer længere nede
      ]
        [set net-force 0] ;;hvis objektet IKKE er i bevægelse (og skub !> friktion)
    ]



    ;;OG SÅ ER DET PÅ DENNE NET-KRAFT, AT DE FØLGENDE BEREGNINGER SKAL FORETAGES!

;;1. Calculate delta-v (acceleration or deceleration)

    ;;F here should be "the vector SUM of external forces" - så friktion er først trukket fra! net-force-variabel

   if styring = "tastatur" [
      ifelse net-force = 0 [ ;;net-force er KUN 0, hvis objektet står stille, og der ikke skubbes (med tilstrækkelig kraft)
        set delta-v 0 ;;no acceleration or deceleration if no (sufficient) push this tick

      ]
     [ ;;hvis abs net-force > 0 :
      set delta-v (net-force / choose-mass) * tick-i-sekunder ;;@scaling med tid - hvordan? (ENTEN her eller i v = u + a*t)
        ;;acceleration = Force / mass ;;acceleration can be 'negative' (modsat fortegn af v, fx hvis intet skub men friktion)
      ] ;;@net-force instead of push-force?
    ]


   if styring = "mus" [
      ifelse net-force = 0 [
        set delta-v 0 ;;no acceleration if standing still and no mouse pull this tick
      ]
      [
        set delta-v (net-force / choose-mass) * tick-i-sekunder ;;a = F/m
      ]
    ]


;;2. Calculate new velocity
    ;;set u [speed] of one-of objects ;;u = initial/current speed ;;(only ever one object at a time)


      ;;kode for hvis objektet er i bevægelse, intet skub, så netforce er bare +friktion eller -friktion ... men friktion skal aldrig give skub i modsat retning, men resultere i stilstand!:
    ifelse ( fratræk-friktion? and (v < 0) and v + delta-v > 0 ) or ( fratræk-friktion? and v > 0 and v + delta-v < 0 )
      [set v 0]
      [set v (v + delta-v)] ;;@tids-scaling allerede gjort ovenfor (a*t). (kode efter chapter 2 pdf!)

    ;;if abs v > 0 [print word "v: " v] ;;@testing

    set fratræk-friktion? FALSE

    ;;set v u + ( a * tick-i-sekunder )  ;;v = u + a*t ;;velocity = initial speed + acceleration * time force is applied
         ;;if no acceleration, new speed = initial speed ;;velocity can be 'negative' (to the left)

    ;;if object hits 'wall'/edge of world, it immediately stops (instead of just building up velocity):
    if (object-x < min-pxcor + 0.5 and [shape != "pushing-right"] of one-of players) or (not kløft? and object-x > max-pxcor - 0.5 and [shape != "pushing-left"] of one-of players) [
      set v 0
    ]



;;3. Calculate displacement
    set delta-x (v * tick-i-sekunder) ;;displacement = velocity * time

   ;; ifelse a = 0 [
     ;; set s delta-v * tick-i-sekunder ;;displacement = velocity * time (if no acceleration) ;;delta-v = velocity after friction is subtracted
    ;;]
    ;;[
     ;;Calculate displacement given initial and final speeds ;;@MAYBE DON'T NEED THIS?! DO THIS? OR SIMPLY CALCULATE NEW VELOCITY, THEN DO s = v*t?
    ;;s = 1/2 * (u + v) * t ;;displacement = 1/2 * (initial speed + final speed) * time force is applied
    ;;set s 0.5 * (u + delta-v) * tick-i-sekunder

    ;;] ;;end of if a != 0


;;5. Move the object!
    set final-displacement delta-x / patch-i-meter ;;delta-x is displacement in meters (divideret ift scaling)

    forward final-displacement ;;moving the object (can be positive or negative)

    set distance-flyttet precision (distance-flyttet + abs final-displacement) 10 ;;@can change precision


;;6. Reset/update variables
    ;;set speed delta-v ;;the new calculated velocity (with friction subtracted), saved to object variable (and used as u in calculations next tick)
    let lower-limit 0.05 ;;@can tweak this (since speed never quite reached 0)
    if v < lower-limit and v > 0 [set v 0] ;;to the right
    if v > (- lower-limit) and v < 0 [set v 0] ;;to the left

    ;;set v precision v 5 ;;@precision can be tweaked


    set speed v ;;speed is an object-variable, v is a global
    if (abs speed) > top-speed [set top-speed speed] ;;update the top speed for this try
    set old-speed speed ;;the previous speed ;;object variable
    set global-speed speed ;;plots continuously
    ;;if old-speed != speed [set global-speed speed] ;;for plotting only when the speed changes @?



    if (abs delta-v) > top-acc [set top-acc delta-v] ;;storing top acceleration

    set total-push-force total-push-force + abs push-force ;;used to calculate arbejde
    set push-force-plot push-force ;;doesn't reset to 0, for plotting
    set push-force 0 ;;reset the skubbekraft once it has been applied


    ] ;;END OF ASK OBJECTS


 ;;SPARKS animation
  if count objects > 0 and not lost? and object-y > min-pycor + 2 [
    ask patch (object-x) (object-y - 2) [
      if (global-speed > 0 or global-speed < 0) and season != "vinter" [ ;;only if the object is moving and it's not winter (ice = 'no' friction)
        sprout-graphics 2 [
          set shape "star" set color yellow set size 0.5 set lifetime 0
          let rando random 2 ;;random little way to set random heading in one of two intervals
          ifelse rando = 1
            [set heading 270 + (random 91)] ;;somewhere between 270 and 360
            [set heading random 91] ;;between 0 and 90
  ]]]]
end



;;--------BEREGNINGER AF FYSISKE STØRRELSER
to-report normalkraft
  report choose-mass * g ;;præcis ligesom tyngdekraften - men i modsat retning!
end

to-report arbejde
  report (skub * nr-of-pushes) / tick-i-sekunder ;;divider med 0.1 = * 10
  ;;hvor mange sekunder har vi skubbet i simuleret tid?

  ;;report abs total-push-force * distance-flyttet ;;A = F * s (enheder: joule = Newton * meter)
  ;;@check: is this right? både F og s er for skub i begge retninger
end

to-report arbejde-monitor ;;just for the interface
  report ( word (precision arbejde 2) " joule" )
end

to-report kinetisk-energi
  report 0.5 * choose-mass * v ^ 2
end

;to-report acceleration ;;kun fra skub, ikke fra friktion
;  if v > 0
;
;  ifelse delta-v > 0
;    [report delta-v]
;    [report 0]
;end



to check-win
  ask houses [
    let win-patches (patch-set patch-here [neighbors] of patch-here)
    ask win-patches [
      let the-object one-of objects-here
      let object-here? count objects-here = 1
      ifelse object-here? [ ;;if the object is on the win-patches

       ask houses [
         set color green ;;the house goes green
        ]



        if [abs speed < 0.03] of the-object [ ;;@ can change accuracy needed to win
          if styring = "mus" and not mouse-down? [set win? TRUE] ;;kan kun vinde, når museknappen løftes
          if styring = "tastatur" [set win? TRUE]
        ]
      ]

      [
        ask houses [
          set house-color-time house-color-time + 1
          if house-color-time = 30 [ ;;@tweak this time? make it depend on tick scaling?
            set color 24 ;; if the-object is not there, house changes back to original color
            set house-color-time 0
          ]
        ]
      ]

  ]
  ]

  if win? [
    set timer-at-end precision timer 2 ;;save how long it took them to win

    make-save-list ;;save all the values from this go

    ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (precision timer-at-end 2)] ;;if won, freeze visual timer at end time
    set last-score score
    set score score + 1
   ;; ask objects [die]
    ask players [set shape "person-happy"]
    ask graphics [die] ask mgraphics [die] ;;to kill off any sparks and the elastic (if mouse control)
    ask patch (max-pxcor - (max-pxcor / 2) - 3) (max-pycor - 6) [set plabel (word "Sejt! Du brugte " (timer-at-end) " sekunder og " nr-of-pushes " skub.") ]
    ask patch (max-pxcor - (max-pxcor / 2) - 8) (max-pycor - 9) [set plabel "Fortsæt det gode arbejde!"]

    set timer-running? FALSE ;;so the timer can start over again with their next first push
    set global-speed 0
    set try-nr try-nr + 1 ;;value that records the nr of finished trys
  ]
end

to update-graphics
  if score != last-score [ ask patch (max-pxcor - 1) (max-pycor - 1) [set plabel (word "Score:" score)] ] ;;update score counter

  if win? or lost? [
     ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (precision timer-at-end 2)] ;;if won or lost, freeze visual timer at end time
     set timer-running? FALSE
  ]


    if timer-running? and not win? and not lost? [
      if object-y = 0 and count objects > 0 [ ;;if the timer is running and the object hasn't fallen
        ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (precision timer 1)] ;;show the timer ticking away
      ]
      ]

    if not timer-running? and not win? and not lost? [
    ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (0)] ;;if timer shouldn't be running, just show 0
  ]


;;SPARKS:
  ask graphics [ ;;the visual sparks
    forward 1
    set lifetime lifetime + 1
    if lifetime >= 2[die]
  ]


;;VISUALISÉR VEKTORER:
  if vis-vektorer? [

 ;;friction vector (UPDATES ALL THE TIME, change this@)
    ask vgraphics with [vector-name = "friktion1" or vector-name = "friktion2"] [die] ;;kill the previous vectors

    create-vgraphics 1 [
      set shape "dot" set color red set size 1 set vector-name "friktion1" setxy 0 vectors-y ;;can tweak position


      if push-force-plot != 0 [ ;;hvis der skubbes dette tick
      hatch 1 [
        setxy (vektor-friktion) vectors-y ;;x-cor indicates the size of the force
        hide-turtle
        set vector-name "friktion2"
        create-link-from myself [ ;;myself refers to the "mommy"/the first vgraphic
         set color red
         set thickness 0.3
         set shape "link2" ;;my custom link arrow
        ]
      ]
    ]
    ] ;;end of if push-force != 0

  ;;skubbekraft-vektor (UPDATES ALL THE TIME RIGHT NOW (CAN CHANGE IF NEEDED))
    ask vgraphics with [vector-name = "skubbekraft1" or vector-name = "skubbekraft2"] [die] ;;kill the previous vectors

     create-vgraphics 1 [
      set shape "dot" set color black set size 1 set vector-name "skubbekraft1" setxy 0 vectors-y

       if abs push-force-plot > 0 [ ;;hvis der er en skubbekraft, tegn vektoren med link:
          hatch 1 [
            setxy (vektor-skubbekraft) vectors-y ;;negative x-cor indicates the size of the force
            hide-turtle
            set vector-name "skubbekraft2"
            create-link-from myself [ ;;myself refers to the "mommy"/the first vgraphic
              set color 52
              set thickness 0.3
              set shape "link2" ;;my custom link arrow
        ]
      ]
     ]
    ]


  ;;tyngdekraft-vektor (@SKAL IKKE UPDATE HELE TIDEN)
;    ask vgraphics with [vector-name = "tyngdekraft1" or vector-name = "tyngdekraft2"] [die] ;;kill the previous vector endpoint
;
;     create-vgraphics 1 [
;      set shape "dot" set color black set size 1 set vector-name "tyngdekraft1" setxy 0 vectors-y
;
;          hatch 1 [
;            setxy 0 (vectors-y - vektor-tyngdekraft) ;;tyngdekraft på y-aksen (nedadgående)
;            hide-turtle
;            set vector-name "tyngdekraft2"
;            create-link-from myself [ ;;myself refers to the "mommy"/the first vgraphic
;              set color violet
;              set thickness 0.3
;              set shape "link2" ;;my custom link arrow
;        ]
;      ]
;    ]



  ;;net-force vektor (resulterende kraft)
    ;;net-force-variabel giver ikke helt mening lige nu - fix det@


  ] ;;END of if vis-vektorer?

end

;;PLACERING AF VEKTOR-DIAGRAM:
to-report vectors-y ;;reporter så det let kan tweakes
  report (min-pycor + 10)
end

to-report vector-divisor ;;just for scaling of the vectors@
  report 6
end


;;i stedet for friktionskraften: det arbejde, den laver

;;mængde energi det tog at deaccelerere objektet
;;forskel på kinetisk energi (- påført). faldet i kinetisk eneri = samlet arbejde, friktionen har udført
  ;;minus skubbe-energien

to-report vektor-friktion ;;the length of the vector representing the friction. Scaled
  ifelse (- friktion / vector-divisor) >= min-pxcor ;;to prevent it from getting too long!
    [

      ifelse push-force-plot >= 0 and (count players with [shape = "pushing-left"] = 0) ;;push-force-plot doesn't reset to 0
        [report (- friktion / vector-divisor)] ;;if pushing right
        [report friktion / vector-divisor]


      if count players with [shape = "pushing-left"] > 0 [
         report friktion / vector-divisor
       ]
  ]
    [ ;;hvis den er for lang til at tegne:
    report (- 30) ;;@the min-pxcor - ONLY FOR THE CAR (but not accurate representation) - change @
  ]
end

to-report vektor-skubbekraft ;;add fail-safe if it gets too long...
  ifelse ( (push-force-plot / vector-divisor) <= max-pxcor ) and ((push-force-plot / vector-divisor) >= min-pxcor) [
    report push-force-plot / vector-divisor ;;hvis den ikke bryder rammerne
  ]
 [ ;;hvis den er for stor til at tegne, tegn bare så lang som muligt (@men ikke præcis repræsentation!):
   ifelse (push-force-plot / vector-divisor) > 0 [
      report 30 ;;if positive (30 = max-pxcor)
    ]
   [
      report (- 30) ;;if negative (-20 = min-pxcor)
    ]
  ]


  if v = 0 [
    report 0 ;;if no vector should be visualised (i.e. they're pushing left into the wall, push-force > 0 but v = 0...)
  ]
end


to-report vektor-tyngdekraft ;;@skal den både vises under stilstand og mens i skub? (indgår vel også i friktion...?)
  ifelse ( (- normalkraft) / vector-divisor ) > min-pycor
    [report ( (- normalkraft) / vector-divisor )] ;;negativ normalkraft (fra reporter) = tyngdekraften
    [report (- 20)] ;;(-20) = min-pycor. Hvis for stor til at tegne (@men ikke præcist!)
end



to check-object ;;to see if they've lost by pushing it over the edge (if there is one)

  if [pcolor = sky or pcolor = 94] of patch (object-x) (object-y - 2) [ ;;check if the patch below the object is sky
    set lost? TRUE
    set global-speed 0 ;;for the plotting
    set try-nr try-nr + 1 ;;value that records the nr of finished trys

    set timer-at-end precision timer 2 ;;save how long it took them to lose

    make-save-list ;;save all the values from this go

    ;;ask patch (min-pxcor + 2) (max-pycor - 1) [set plabel (precision timer-at-end 2)] ;;if lost, freeze visual timer at end time
    set timer-running? FALSE

    ask players [set shape "person"]

    ask graphics [die] ask mgraphics [die] ;;kills off any sparks and the elastic

    ask objects [
      set shape (word shape "-rot") ;;objects change to rotatable shape (only difference)

      set speed 0
      set heading 0
    ]
  ]

  ;;if any? objects with [pxcor > (max-pxcor - 10)] [ ;;if the object has fallen over the edge
    ;;ask objects [
      ;;setxy (max-pxcor - 5) -17]
  ;;]
end

to fail-animation ;;what happens when the object gets pushed over the edge
  ifelse object-y > -18 [ ;;if object hasn't reached the ground yet
   ask objects [
      set real-heading 160

      if object-x >= max-pxcor [set real-heading 180] ;;to fix bug, if super fast speed object just ends up spinning on the world edge forever

      set heading real-heading ;;it really keeps heading in the same direction every time
      fd 1
      set apparent-heading apparent-heading + 10 ;;but looks like it's spinning each turn
      set heading apparent-heading ;;that's all the user sees visually (due to tick-based updates)
    ]
  ]
 [ ;;if object HAS reached the ground:
    ifelse count explosions < 8 [
      ask patches with [count objects-here = 1] [
      sprout-explosions 1 [ ;;let's have some explosions :)
        set color yellow
        set size 4
        set shape "star-rot"
      ]
      sprout-explosions 1 [ ;;different color
        set color orange
        set size 4
        set shape "star-rot"

      ]
    ]
    ]
    [ ;;if explosions are done

     ;;LITTLE FIRE ANIMATION:
      if count explosions with [shape = "fire"] = 0 [
          ask patches with [count objects-here = 1] [
        sprout-explosions 1 [set shape "fire" set size 4 set color yellow set heading 10] ;;fire on top of the explosion ;)
      ]
      ]

    ask patch (max-pxcor - (max-pxcor / 2) - 6) (max-pycor - 6) [set plabel (word "Åh nej, objektet faldt ud over kanten!") ]
    ask patch (max-pxcor - (max-pxcor / 2) - 7) (max-pycor - 9) [set plabel "Tryk på 'Genstart' for at prøve igen!"]

      ;;user-message "You failed! :-( Try again!"
     ;;genstart ;;starts the level over
    ]
  ]
end



;;SAVING THE VALUES

to make-save-list
  ;;set save-list [] ;;@now overwritten after each go (if we've already sent previous lists to a server or something)? Or should all gos be saved?
  ;;set save-list lput (list "time" timer-at-end) save-list ;;nested list? (first = variable, second = value)

  set save-list lput (list objekt choose-mass skub nr-of-pushes distance-flyttet gnidnings-kof timer-at-end) save-list
    ;;objektet, objektets masse, kraft i hvert skub, antal skub, total distance, gnidningskoefficient, tid
end



;;;;;;;;;;;;;;;;;;;;;;;
;;;MOVING THE PLAYER;;;
;;;;;;;;;;;;;;;;;;;;;;;

to move-person
  if current-opgave = "1. Flytning af genstande" or current-opgave = "2. Betydning af masse"  or current-opgave = "3. Betydning af friktion" [
    set skub 150
  ] ;;@kan ændre fastsat værdi

  if current-opgave = "5. Betydning af skubbekraft" and show-timer != "Spillet kører ikke endnu" [
   set skub current-skub ;;så de ikke kan ændre det efter start
  ]

  if styring = "tastatur" and win? = FALSE [

  if action != 0 [
    if action = 1 [
      move-left
    ]
    if action = 2 [
      move-right
    ]

      set action 0
  ]
  ]
end

to move-left
  if not lost? [
    ask players [
    ifelse (kløft? and object-x < max-pxcor - 10) or (not kløft? and object-x < max-pxcor - 1) ;;if the sheep isn't over the edge (when lost? is too slow) OR to the very right (when no cliff)
        [setxy (object-x + 1) 0]
        [setxy max-pxcor 0]
    set shape "pushing-left"
  ]

  if not timer-running? [reset-timer] ;;if it's the very first push, start the timer
  set timer-running? TRUE

  set push-force push-force - skub

  ;;let skub-scaled skub * tick-i-sekunder ;;GANGET (før divideret, fejl?!) for at få det til at passe (i interfacet: skub specificeret i N/s)
  ;;set push-force (push-force - skub-scaled) ;;pushing to the left means negative push-force in these calculations (negative speed = going to the left)

  set nr-of-pushes nr-of-pushes + 1
  ]
end

to move-right
 if not lost? [
  ask players [
    ifelse object-x > min-pxcor + 1
        [setxy (object-x + -1) 0] ;;@
        [setxy min-pxcor 0]
    set shape "pushing-right"


    if kløft? and xcor > (max-pxcor - 10) [ ;;@change to currently-kløft?
        set xcor (max-pxcor - 10) ;;the player can't move over the edge
      ]
  ]

  if not timer-running? [reset-timer] ;;if it's the very first push, start the timer
  set timer-running? TRUE

  set push-force push-force + skub

  ;;let skub-scaled skub * tick-i-sekunder ;;(GANGET) divideret for at få det til at passe (i interfacet: skub specificeret i N/s)
  ;;set push-force push-force + skub-scaled

  set nr-of-pushes nr-of-pushes + 1
  ]
end


;;;GRAPHICS;;;

to make-world
  ask players [die]
  ask objects [die]

  apply-opgave ;;fastsætter de tvungne/rette indstillinger for den valgte opgave (årstid, kløft, objekt...)


  if season = "sommer" [
  ask patches [ ;;summer sky and grass
    ifelse pycor > -2 or (pxcor > (max-pxcor - 10) and pycor > -19)  [set pcolor sky] [ set pcolor scale-color green ((random 500) + 5000) 0 9000 ] ;;summer
  ]
    if not kløft? [
      ask patches [
        if pycor <= -2 [ set pcolor scale-color green ((random 500) + 5000) 0 9000 ] ;;if no cliff, extend the grass
      ]
    ]
  ]

  if season = "vinter" [
    ask patches [ ;;winter sky and snow
    ifelse pycor > -2 or (pxcor > (max-pxcor - 10) and pycor > -19)  [set pcolor 94] [ set pcolor scale-color white ((random 500) + 8000) 0 9000 ]
    if pycor < -1 and pycor > -3 and pxcor < (max-pxcor - 9) [set pcolor scale-color 88 ((random 500) + 7000) 0 9000] ;;and ice
  ]
    if not kløft? [
      ask patches [
        if pycor <= -2 [ set pcolor scale-color white ((random 500) + 8000) 0 9000 ] ;;if no cliff, extend the snow
        if pycor < -1 and pycor > -3 [set pcolor scale-color 88 ((random 500) + 7000) 0 9000] ;;and ice
      ]
    ]
  ]

   create-houses 1 [ ;;the house
    ifelse season = "vinter" [set shape "house-snow"] [set shape "house"]
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

to apply-opgave ;;køres i 'make-world' i både Opsætning og Genstart

  if current-opgave != "Fri leg" [ ;;add levels WITHOUT forced tastatur-styring
    set styring "tastatur"
  ]

;;KLØFT
  if current-opgave != "Fri leg" and current-opgave != "6. Betydning af kløft" [ ;;(tilføj levels med valgfri kløft her)
    set kløft? false ;;(ellers ingen kløft)
  ]

 ;;levels med fastsat sommer:
  if current-opgave = "1. Flytning af genstande" or current-opgave = "2. Betydning af masse"  or current-opgave = "5. Betydning af skubbekraft" or current-opgave = "6. Betydning af kløft" [
   set vinter? false
  ]

  ;;levels med fastsat skub:
  if current-opgave = "1. Flytning af genstande" or current-opgave = "2. Betydning af masse"  or current-opgave = "3. Betydning af friktion" or current-opgave = "6. Betydning af kløft" [
    set skub 150 ;;@kan ændre fast værdi (også i move-person)
  ]

   ;;valgfrit skub:
  if current-opgave = "5. Betydning af skubbekraft" or current-opgave = "Fri leg" [
    set skub vælg-kraft set current-skub skub
  ]


 ;;forced objects:
  if current-opgave = "2. Betydning af masse" or current-opgave = "3. Betydning af friktion" or current-opgave = "5. Betydning af skubbekraft" [
    set objekt "kasse"
  ]

  set current-object objekt

  ;;by not adding the free levels to these, they can then still choose cliff or winter themselves using the switch (and cliff is applied in make-world):
  ifelse vinter?
    [set season "vinter"]
    [set season "sommer"]
end

to vis-instruks ;;køres i setup
  if current-opgave = "1. Flytning af genstande" [ ;;@...
    output-print "FLYTNING AF GENSTANDE"
    output-print "Hej! Vil du hjælpe mig med at flytte ind i mit nye hus?"
    output-print "    1. Vælg en genstand i 'objekt'-drop-down-menuen."
    output-print "    2. Tryk på 'Genstart'."
    output-print "    3. Tryk på 'Spil'."
    output-print "    4. Skub til genstanden med 'J' og 'L' tasterne på tastaturet."
    output-print "    5. Skub genstanden hen foran huset. Den skal ligge helt stille."
    output-print "(- spørgsmål her?)"
    output-print "(- guide til output her?)"

  ]

  if current-opgave = "2. Betydning af masse" [
    output-print "BETYDNING AF MASSE"
    output-print "Jeg kan variere, hvor tungt jeg pakker mine flyttekasser..."
    output-print "Hvordan påvirker massen kassens fart, bevægelseslængde og acceleration?"
    output-print "    1. Vælg en masse for flyttekassen med 'vælg-masse'-slideren."
    output-print "    2. Tryk på 'Genstart'."
    output-print "    3. Skub til kassen!"
    output-print "Du kan se bevægelsesafstanden i 'Meter fra start'."
    output-print "Grafen viser kassens fart over tid."
    output-print "- (mere her?)"
    output-print "PS. Tryk på 'Opsætning', hvis du vil viske plottet rent"
  ]

    if current-opgave = "3. Betydning af friktion" [
    output-print "BETYDNING AF FRIKTION"
    output-print "Hvad nu, hvis jeg flyttede ind om vinteren i stedet...?"
    output-print "Hvilken betydning har underlagets friktion/gnidningsmodstand?"
    output-print "    1. Vælg årstid med vinter?-kontakten."
    output-print "    2. Tryk på 'Genstart'."
    output-print "    3. Skub til kassen."
    output-print "Du kan se bevægelsesafstanden i 'Meter fra start'."
    output-print "Grafen viser kassens fart over tid."
    output-print "Prøv at skubbe til kassen både om sommeren og vinteren."
    output-print "- (spørgsmål eller andet her?)"
    output-print "PS. Tryk på Opsætning, hvis du vil viske plottet rent"
  ]

  if current-opgave = "5. Betydning af skubbekraft" [
    output-print "BETYDNING AF SKUBBEKRAFT"
    output-print "Hvad nu, hvis jeg varierer, hvor hårdt jeg skubber...?"
    output-print "Hvilken betydning har kraften i skubbet?"
    output-print "    1. Vælg størrelsen på skubbekraften med 'vælg-kraft'-slideren."
    output-print "    2. Tryk på 'Genstart'."
    output-print "    3. Skub til kassen."
    output-print "Du kan se bevægelsesafstanden i 'Meter fra start'."
    output-print "Grafen viser kassens fart over tid."
    output-print "- (evt. find den skubbekraft, som får massen i mål på ET enkelt skub?)"
    output-print "(lige nu kan man ikke ændre kraften undervejs i et forsøg!)"
    output-print "PS. Tryk på Opsætning, hvis du vil viske plottet rent"
  ]

  if current-opgave = "(Undersøg skub og træk)" [
    output-print "UNDERSØG SKUB OG TRÆK"
    output-print "(vælg muse-styring...)"
    output-print "(ikke færdigt endnu)"
  ]

  if current-opgave = "6. Betydning af kløft" [
    output-print "BETYDNING AF KLØFT"
    output-print "Jeg har altid drømt om et hus med udsigt..."
    output-print "Men pas nu på, at mine ting ikke ryger ud over kanten!"
    output-print "    1. Brug 'kløft?'-kontakten til at vælge, om der skal være en kløft."
    output-print "    2. Vælg en genstand i 'objekt'-drop-down-menuen."
    output-print "    3. Tryk på 'Genstart'."
    output-print "    4. Skub genstanden hen til huset."
    output-print "(uden kløft er det her magen til opgave 1)"
    output-print "(- prøv at gøre det så effektivt som muligt?)"
    output-print "(output: 'Antal skub', 'Tid brugt', 'Samlet arbejde udført')"
    output-print "(skal plottet også være tændt og vise fart over tid???)"
  ]


  if current-opgave = "Fri leg" [
    output-print "FRI LEG"
    output-print "Nu har du muligheden for at ændre på lige, hvad du vil!"
    output-print "    1. Indstil: Masse (vælg-masse), skubbekraft (vælg-kraft),"
    output-print "    friktion (vinter?), landskab (kløft?), udseende (objekt)."
    output-print "    2. Tryk på 'Genstart', når du har valgt dine indstillinger. "
    output-print "    3. Skub til tingen!"
    output-print "- Udfordring: Min bil er godt nok tung... kan du få den hen til huset?"
    output-print "(^^men virker kun, hvis vi gør så de ikke kan justere massen selv)"
    output-print "PS. Tryk på Opsætning, hvis du vil viske plottet rent"
    output-print "PPS. Tak for flyttehjælpen! NU har jeg brug for at slappe af..."
    output-print "    ... men hov, jeg glemte vist helt at pakke min sofa!!!"
  ]

end


;;OBJECTS
to make-object
  ask objects [die]
  ask explosions [die]
  set push-force 0
  set total-push-force 0

  ;;clear yay you won patches
  ask patch (max-pxcor - (max-pxcor / 2) - 3) (max-pycor - 6) [set plabel ""]
  ask patch (max-pxcor - (max-pxcor / 2) - 8) (max-pycor - 9) [set plabel ""]

  ;;clear oh no you lost patches
  ask patch (max-pxcor - (max-pxcor / 2) - 6) (max-pycor - 6) [set plabel "" ]
  ask patch (max-pxcor - (max-pxcor / 2) - 7) (max-pycor - 9) [set plabel ""]


;;;;;;;;;;;;
;;OBJEKTER;;
;;;;;;;;;;;;

  if objekt = "æble" [
    ;;set kløft? FALSE ;;ingen afgrund?
    create-objects 1 [
      set shape "apple-small"
      set object-name objekt ;;turtle variable
      set color red
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 0.2
      set plot-color red ;;a global that determines the output plot line color for this object
    ]
  ]

  if objekt = "kat" [
    ;;set kløft? TRUE
    create-objects 1 [
      set shape "my-cat2"
      set object-name objekt
      set color 7
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 5
      set plot-color grey
    ]
  ]

  if objekt = "kasse" [
    ;;set kløft? TRUE
    create-objects 1 [
      set shape "flyttekasse"
      set object-name objekt
      set color 37
      set size 3 ;
     set label (word vælg-masse " kg")
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 15
      set plot-color brown
    ]
  ]

  if objekt = "får" [
    ;;set kløft? TRUE ;;nu med afgrund?
    create-objects 1 [
      set shape "sheep"
      set object-name objekt
      set color white
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 50
      set plot-color green
    ]
  ]

   if objekt = "køleskab" [
    ;;set kløft?
    create-objects 1 [
      set shape "fridge"
      set object-name objekt
      set color white
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 80
      set plot-color blue
    ]
  ]

   if objekt = "bil" [
    ;;set kløft? TRUE
    create-objects 1 [
      set shape "push-car" ;;push-car is my modified non-floating shape (and has a rotatable push-car-rot shape for the fail animation)
      set object-name objekt
      set color yellow
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 1400
      set plot-color yellow
    ]
  ]



;;overwrite choose-mass hvis de selv styrer massen:
  if current-opgave = "2. Betydning af masse" or current-opgave = "Fri leg"
     [set choose-mass vælg-masse set current-vælg-masse vælg-masse] ;;når de selv varierer massen med interface-slider



end

to genstart
  ; JB - Track each `Genstart` for different plot names
  set genstart-number (genstart-number + 1)

  ask patch (max-pxcor - (max-pxcor / 2) - 8) (max-pycor - 5) [set plabel "" ]
  ask patch (max-pxcor - (max-pxcor / 2) - 13) (max-pycor - 8) [set plabel ""]

  ask vgraphics [die] ;;the vectors

  set current-opgave opgave
  set current-object objekt ;;gem fra chooseren til global variabel, så det ikke ændres, hvis de ændrer det
  ifelse vinter? [set currently-vinter? true] [set currently-vinter? false]
  ;;set current-vælg-masse vælg-masse
  ;;set current-skub vælg-kraft

  make-world
  make-object


;;dynamic plot pens:

  if current-opgave = "2. Betydning af masse" [ ;;kaldes i 'Genstart' OG 'setup' (til opgave med varierende masse)
    create-temporary-plot-pen ( word "Fart (kasse, " current-vælg-masse " kg) " genstart-number )

    ;;workaround:
    plot-pen-up
    plotxy 0 0
    plot-pen-down

  ]

  if current-opgave = "5. Betydning af skubbekraft" [ ;;kaldes i 'Genstart' OG setup (varierende skubbekraft)
    create-temporary-plot-pen ( word "Fart (skub på " current-skub " N) " genstart-number ) ;;kun hvis de ikke må ændre skubbekraften undervejs i forsøget! ;;kan gøres sådan

    ;;workaround:
    plot-pen-up
    plotxy 0 0
    plot-pen-down
  ]

   if current-opgave = "Fri leg" [ ;;mulighed for at de vælger alle objekter og begge underlag! ;;@og enhver skubbekraft! gør det dynamisk!
     ;;plot-pen-reset ;;@?
    ifelse vinter?
      [create-temporary-plot-pen ( word current-vælg-masse " kg, " current-skub " N (ingen friktion) " genstart-number )]
      [create-temporary-plot-pen ( word current-vælg-masse " kg, " current-skub " N (med friktion) " genstart-number )]
    ;;plot-pen-up
    set plot-color item color-counter base-colors ;;built-in NetLogo list ;;@change to my own custom list
    ifelse color-counter < (length my-colors) - 1 ;;-1 since 0 indicates the first item
      [set color-counter color-counter + 1]
      [set color-counter 0]

    ; JB - Workaround for zeroing plots issue - plot the starting `plotxy 0 0` so we don't do it as part of `update-plot`
    set-plot-pen-color plot-color
    plot-pen-up
    plotxy 0 0
    plot-pen-down
  ]

  set win? FALSE set lost? FALSE
  ask players [setxy (min-pxcor + 1) 0 set shape "person"]
  set push-force 0
  set net-force 0
  set v 0
  set total-push-force 0
  ask objects [set speed 0]
  set nr-of-pushes 0 ;;@could save a total nr of pushes across levels?
  set distance-flyttet 0 ;;@igen: could save cumulative across levels
  set timer-running? FALSE ;;so the timer can start over again with their first push



end

to-report show-timer
  if lost? or win? [report timer-at-end]

  ifelse timer-running? [
   report timer
  ]
  [
    ;;report "Spillet kører ikke endnu"
    report 0 ;;så det dynamiske output-plot starter i 0
  ]
end

to-report timer-interface
  ifelse timer-running? [report show-timer] [report "Spillet kører ikke endnu"]
end


;;PLOTS
to setup-plot ;;køres i setup ('Opsætning')
  set-current-plot "Output"


  if current-opgave = "2. Betydning af masse" [ ;;den her kaldes også i 'Genstart'
    create-temporary-plot-pen ( word "Fart (kasse, " current-vælg-masse " kg) " genstart-number )

    ;;workaroud:
    plotxy 0 0

  ]

  if current-opgave = "3. Betydning af friktion" [
    create-temporary-plot-pen "Fart (med friktion)"
    create-temporary-plot-pen "Fart (ingen friktion)"
  ]

;  if current-opgave = "4. Masse og friktion" [
;    ;
;  ]

  if current-opgave = "5. Betydning af skubbekraft" [ ;;den her kaldes også i 'Genstart'
    create-temporary-plot-pen ( word "Fart (skub på " current-skub " N) " genstart-number ) ;;kun hvis de ikke må ændre skubbekraften undervejs i forsøget! ;;kan gøres sådan

    ;;workaround:
    set-plot-pen-color plot-color
    plotxy 0 0
  ]



 if current-opgave = "Fri leg" [ ;;mulighed for at de vælger alle objekter og begge underlag! ;;@og enhver skubbekraft! gør det dynamisk!
      set my-colors [5 15 25 35 45 55 85 105 125 135] ;;custom list of colors used in "Fri leg"

    ifelse vinter? [set currently-vinter? true] [set currently-vinter? false]
    ifelse currently-vinter? = true
      [
        create-temporary-plot-pen ( word current-vælg-masse " kg, " current-skub " N (ingen friktion) " genstart-number )
    ]
      [
      create-temporary-plot-pen ( word current-vælg-masse " kg, " current-skub " N (med friktion) " genstart-number )
    ]
    set plot-color item color-counter base-colors ;;built-in NetLogo list ;;@change to my own custom list
    ifelse color-counter < (length my-colors) - 1 ;;-1 since 0 indicates the first item
      [set color-counter color-counter + 1]
      [set color-counter 0]

    ; JB - Workaround for zeroing plots issue - plot the starting `plotxy 0 0` so we don't do it as part of `update-plot`
    set-plot-pen-color plot-color
    plotxy 0 0

  ]

end

to update-plot

  if show-timer = 0 and current-opgave != "1. Flytning af genstande" and current-opgave != "6. Betydning af kløft" [ ;;@skift her, hvis kløft skal vise plot

    ; JB - Workaround for zeroing plots issue - do not `plotxy 0 0` multiple times before the simulation "starts"
    ; plot-pen-up
    ; plotxy 0 0
    ; plot-pen-down
    ;;@tilføj evt.: hvis samme indstillinger, skal den tidligere plot-linje slettes?
  ]

  if current-opgave = "2. Betydning af masse" [
    set-current-plot-pen ( word "Fart (kasse, " current-vælg-masse " kg) " genstart-number ) ;;pre-created in both/either Opsætning and/or Genstart

  ;;set pen color depending on the chosen mass:
    let vælg-masse-string (word current-vælg-masse) ;from number to string
    ifelse current-vælg-masse >= 10
      [
        let first-digit first vælg-masse-string
        set plot-color (word first-digit 5)

        if current-vælg-masse > 99 [ ;;special case hvis den er præcis 100
          set plot-color "115"
        ]
    ]
      [ ;;if mass < 10:
      set plot-color "5"
    ]

    set-plot-pen-color read-from-string plot-color ;;@make it random/visualising the different weights! a gradient!

    ;;workaround:
    if show-timer != 0 [
      plotxy show-timer (abs global-speed) ;;real time on the x-axis (starting from first push), speed on the y axis
    ]

  ]


  if current-opgave = "3. Betydning af friktion" [
    ifelse season = "vinter" [
      set-current-plot-pen ( word "Fart (ingen friktion)" )
      set-plot-pen-color plot-color + 2 ;;@can tweak plot colors to make more readable
      plotxy show-timer (abs global-speed)
    ]
    [ ;;if summer:
      set-current-plot-pen ( word "Fart (med friktion)" )
      set-plot-pen-color plot-color - 2 ;;@can tweak plot colors to make more readable
      plotxy show-timer (abs global-speed)
    ]
  ]


  if current-opgave = "5. Betydning af skubbekraft" [
    set-current-plot-pen ( word "Fart (skub på " current-skub " N) " genstart-number )

  ;;pen color depends on the size of the skubbekraft:
    ifelse current-skub >= 100
    [
      let first-digit first (word current-skub)
      set plot-color (word first-digit 5)

        if current-skub > 999 [ ;;special case hvis den er præcis 1000
          set plot-color "115"
        ]
    ]
    [ ;;if skub < 100:
      set plot-color "5"
    ]

    set-plot-pen-color read-from-string plot-color

;;workaround:
    if show-timer != 0 [
      plotxy show-timer (abs global-speed) ;;real time on the x-axis (starting from first push), speed on the y axis
    ]
  ]


  if current-opgave = "Fri leg" [
    ifelse currently-vinter? = true
      [set-current-plot-pen ( word current-vælg-masse " kg, " current-skub " N (ingen friktion) " genstart-number )]
      [set-current-plot-pen ( word current-vælg-masse " kg, " current-skub " N (med friktion) " genstart-number )]

    ;;set plot-color one-of base-colors ;;this is run in setup-plot
    set-plot-pen-color plot-color

    ; JB - Workaround for zeroing plots issue - do not `plotxy 0 0` multiple times before the simulation "starts"
    if show-timer != 0 [
      plotxy show-timer (abs global-speed)
    ]

  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
225
10
965
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
10
185
80
218
Opsætning
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
85
185
148
218
Spil
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
225
510
290
543
VENSTRE
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
290
510
355
543
HØJRE
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

CHOOSER
110
95
205
140
objekt
objekt
"æble" "kat" "kasse" "får" "køleskab" "bil"
2

BUTTON
155
185
215
220
Genstart
genstart
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

SLIDER
405
510
577
543
hastighed
hastighed
1
100
42.0
1
1
%
HORIZONTAL

MONITOR
710
510
840
555
Tid brugt
timer-interface
17
1
11

MONITOR
645
510
710
555
Antal skub
nr-of-pushes
17
1
11

SWITCH
20
145
110
178
kløft?
kløft?
1
1
-1000

CHOOSER
20
95
112
140
styring
styring
"mus" "tastatur"
1

MONITOR
1120
435
1205
480
Meter fra start
object-x + 26
2
1
11

TEXTBOX
450
545
535
563
Spillets hastighed
11
0.0
1

MONITOR
1430
435
1500
480
Friktion
precision friktion 2
17
1
11

PLOT
970
195
1505
435
Output
Tid
Fart
0.0
1.0
0.0
1.0
true
true
"" "if opgave = \"Startspil\" [clear-plot auto-plot-off]"
PENS

SWITCH
115
145
205
178
vinter?
vinter?
1
1
-1000

MONITOR
970
435
1047
480
Fart
precision (abs v) 2
17
1
11

CHOOSER
20
45
205
90
opgave
opgave
"1. Flytning af genstande" "2. Betydning af masse" "3. Betydning af friktion" "(4. Masse og friktion)" "5. Betydning af skubbekraft" "6. Betydning af kløft" "Fri leg"
0

MONITOR
1045
435
1122
480
Topfart
precision (abs [top-speed] of one-of objects) 2
17
1
11

OUTPUT
970
30
1505
190
11

TEXTBOX
20
10
200
50
1. Vælg opgave og tryk på 'Opsætning'.
13
0.0
1

MONITOR
125
225
190
270
Masse (kg)
choose-mass
17
1
11

TEXTBOX
975
10
1205
30
2. Læs instrukser herunder
13
0.0
1

TEXTBOX
770
605
920
623
NIL
11
0.0
1

SLIDER
5
335
215
368
vælg-masse
vælg-masse
1
100
35.0
1
1
kg
HORIZONTAL

TEXTBOX
30
310
205
328
Kun til opgave 2 (og fri leg):
12
0.0
1

TEXTBOX
35
370
200
388
Vælg masse og tryk på 'Genstart'.
11
0.0
1

MONITOR
840
510
965
555
Samlet arbejde udført
arbejde-monitor
17
1
11

MONITOR
1350
435
1430
480
Kinetisk energi
precision kinetisk-energi 2
17
1
11

MONITOR
1205
435
1300
480
Top-acceleration
precision ([top-acc] of one-of objects) 2
17
1
11

SWITCH
1065
530
1215
563
auto-indstil-opgaver?
auto-indstil-opgaver?
1
1
-1000

TEXTBOX
1220
535
1395
576
(funktionsløs lige nu - men kan være løsning på differentiering?)
11
0.0
1

MONITOR
35
225
125
270
Skubbekraft (N)
skub
17
1
11

SLIDER
0
440
210
473
vælg-kraft
vælg-kraft
0
1000
500.0
10
1
N
HORIZONTAL

TEXTBOX
25
415
210
433
Kun til opgave 5 (og fri leg):
12
0.0
1

TEXTBOX
35
475
195
493
Vælg kraft og tryk på 'Genstart'.
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

apple
false
0
Polygon -7500403 true true 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

apple-small
false
0
Polygon -7500403 true true 107 195 92 225 92 255 107 285 137 300 151 295 167 300 197 285 212 255 212 225 197 195 167 180 152 180 152 180 137 180
Polygon -16777216 true false 149 194 154 174 145 162 154 157 167 172 159 192

apple-small-rot
true
0
Polygon -7500403 true true 107 195 92 225 92 255 107 285 137 300 151 295 167 300 197 285 212 255 212 225 197 195 167 180 152 180 152 180 137 180
Polygon -16777216 true false 149 194 154 174 145 162 154 157 167 172 159 192

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

fire
true
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

flyttekasse
false
0
Rectangle -7500403 true true 60 165 240 300
Polygon -7500403 true true 195 165 240 120 285 120 240 180
Polygon -7500403 true true 105 165 60 120 15 120 60 180
Line -6459832 false 240 180 195 165
Line -6459832 false 60 180 105 165
Line -6459832 false 60 180 240 180
Line -6459832 false 105 165 195 165
Line -6459832 false 240 180 285 120
Line -6459832 false 60 180 15 120
Line -6459832 false 195 165 240 120
Line -6459832 false 105 165 60 120
Line -6459832 false 285 120 240 120
Line -6459832 false 15 120 60 120
Line -6459832 false 240 180 240 300
Line -6459832 false 60 180 60 300
Line -6459832 false 240 300 60 300
Polygon -6459832 true false 150 180 240 180 193 166 105 166 60 180

flyttekasse-rot
true
0
Rectangle -7500403 true true 60 165 240 300
Polygon -7500403 true true 195 165 240 120 285 120 240 180
Polygon -7500403 true true 105 165 60 120 15 120 60 180
Line -6459832 false 240 180 195 165
Line -6459832 false 60 180 105 165
Line -6459832 false 60 180 240 180
Line -6459832 false 105 165 195 165
Line -6459832 false 240 180 285 120
Line -6459832 false 60 180 15 120
Line -6459832 false 195 165 240 120
Line -6459832 false 105 165 60 120
Line -6459832 false 285 120 240 120
Line -6459832 false 15 120 60 120
Line -6459832 false 240 180 240 300
Line -6459832 false 60 180 60 300
Line -6459832 false 240 300 60 300
Polygon -6459832 true false 150 180 240 180 193 166 105 166 60 180

fridge
false
0
Rectangle -7500403 true true 68 1 233 301
Rectangle -16777216 true false 198 130 213 235
Line -16777216 false 68 90 233 90
Rectangle -16777216 true false 199 15 214 60

fridge-rot
true
0
Rectangle -7500403 true true 68 1 233 301
Rectangle -16777216 true false 198 130 213 235
Line -16777216 false 68 90 233 90
Rectangle -16777216 true false 199 15 214 60

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house-snow
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -1 true false 15 120 150 15 285 120
Line -16777216 false 30 120 270 120
Polygon -7500403 true true 15 120 285 120 225 75 75 75 15 120
Polygon -1 true false 120 60 75 90 105 105 120 120 135 105 150 90 150 60 135 45 120 45
Polygon -1 true false 165 45 135 75 165 105 180 105 195 105 225 90 195 60 180 60 180 45
Polygon -1 true false 105 45 30 105 60 120 75 105 75 105 105 75 150 60 135 45 150 15
Polygon -1 true false 195 45 270 105 240 120 225 105 225 105 195 75 150 60 165 45 150 15
Circle -1 true false 165 90 30
Circle -1 true false 135 75 30
Circle -1 true false 105 90 30
Circle -1 true false 60 75 30
Circle -1 true false 45 90 30
Circle -1 true false 225 90 30
Circle -1 true false 210 75 30
Circle -1 true false 75 75 30
Circle -1 true false 195 75 30

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

my-cat
false
0
Circle -7500403 true true 150 105 120
Polygon -7500403 true true 195 195 120 210 75 210 46 211 20 274 42 301 164 300 179 300 209 300 269 300 278 301 290 295 299 285 289 270 243 264 226 241 240 210 238 205 241 196 211 196
Polygon -7500403 true true 150 165 149 70 209 115 164 160
Polygon -7500403 true true 270 165 272 72 212 117 257 162
Polygon -7500403 true true 13 238 10 194 7 151 59 75 110 79 130 104 114 108 76 95 38 152 39 188 61 209 54 251
Polygon -16777216 true false 212 166 227 166 212 181 197 166 212 166
Polygon -16777216 true false 195 75
Circle -7500403 true true 9 206 86
Polygon -1184463 true false 165 144 178 130 196 130 208 144 193 152 178 152
Circle -16777216 true false 180 133 14
Line -16777216 false 224 193 197 193
Polygon -1184463 true false 218 144 231 130 249 130 261 144 246 152 231 152
Circle -16777216 true false 233 133 14

my-cat-rot
true
0
Circle -7500403 true true 150 105 120
Polygon -7500403 true true 195 195 120 210 75 210 46 211 20 274 42 301 164 300 179 300 209 300 269 300 278 301 290 295 299 285 289 270 243 264 226 241 240 210 238 205 241 196 211 196
Polygon -7500403 true true 150 165 149 70 209 115 164 160
Polygon -7500403 true true 270 165 272 72 212 117 257 162
Polygon -7500403 true true 13 238 10 194 7 151 59 75 110 79 130 104 114 108 76 95 38 152 39 188 61 209 54 251
Polygon -16777216 true false 212 166 227 166 212 181 197 166 212 166
Polygon -16777216 true false 195 75
Circle -7500403 true true 9 206 86
Polygon -1184463 true false 165 144 178 130 196 130 208 144 193 152 178 152
Circle -16777216 true false 180 133 14
Line -16777216 false 224 193 197 193
Polygon -1184463 true false 218 144 231 130 249 130 261 144 246 152 231 152
Circle -16777216 true false 233 133 14

my-cat2
false
0
Polygon -7500403 true true 158 174 150 94 217 124 172 169
Circle -7500403 true true 156 110 110
Polygon -7500403 true true 265 172 273 92 206 122 251 167
Polygon -16777216 true false 212 170 227 170 212 185 197 170 212 170
Polygon -16777216 true false 195 75
Polygon -1184463 true false 166 155 179 141 197 141 209 155 194 163 179 163
Circle -16777216 true false 181 144 14
Line -16777216 false 226 198 199 198
Polygon -1184463 true false 215 154 228 140 246 140 258 154 243 162 228 162
Circle -16777216 true false 230 143 14
Polygon -7500403 true true 229 217 247 223 256 239 256 284 269 287 267 299 151 300 143 292 149 284 161 283 162 227 171 220 187 216
Polygon -7500403 true true 192 215 174 221 165 237 165 282 152 285 154 297 270 298 278 290 272 282 260 281 259 225 250 218 234 214
Polygon -7500403 true true 159 288 145 275 128 265 113 248 108 235 106 220 105 205 102 182 105 161 111 149 122 149 126 157 122 167 120 176 119 189 119 199 119 211 119 219 124 233 127 241 134 253 148 261 170 264

my-cat2-rot
true
0
Polygon -7500403 true true 158 174 150 94 217 124 172 169
Circle -7500403 true true 156 110 110
Polygon -7500403 true true 265 172 273 92 206 122 251 167
Polygon -16777216 true false 212 170 227 170 212 185 197 170 212 170
Polygon -16777216 true false 195 75
Polygon -1184463 true false 166 155 179 141 197 141 209 155 194 163 179 163
Circle -16777216 true false 181 144 14
Line -16777216 false 226 198 199 198
Polygon -1184463 true false 215 154 228 140 246 140 258 154 243 162 228 162
Circle -16777216 true false 230 143 14
Polygon -7500403 true true 229 217 247 223 256 239 256 284 269 287 267 299 151 300 143 292 149 284 161 283 162 227 171 220 187 216
Polygon -7500403 true true 192 215 174 221 165 237 165 282 152 285 154 297 270 298 278 290 272 282 260 281 259 225 250 218 234 214
Polygon -7500403 true true 159 288 145 275 128 265 113 248 108 235 106 220 105 205 102 182 105 161 111 149 122 149 126 157 122 167 120 176 119 189 119 199 119 211 119 219 124 233 127 241 134 253 148 261 170 264

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

person-happy
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 120 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90
Rectangle -7500403 true true 135 75 165 94
Polygon -7500403 true true 60 15 120 90 120 135 45 45
Polygon -7500403 true true 240 15 180 90 180 135 255 45

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

push-car
false
0
Polygon -7500403 true true 300 210 279 194 261 174 240 165 226 162 213 136 203 114 185 93 159 80 135 80 75 90 0 180 0 195 0 255 300 255 300 210
Circle -16777216 true false 180 210 90
Circle -16777216 true false 30 210 90
Polygon -16777216 true false 162 110 132 108 134 165 209 165 194 135 189 126 180 119
Circle -7500403 true true 47 225 58
Circle -7500403 true true 195 225 58

push-car-rot
true
0
Polygon -7500403 true true 300 210 279 194 261 174 240 165 226 162 213 136 203 114 185 93 159 80 135 80 75 90 0 180 0 195 0 255 300 255 300 210
Circle -16777216 true false 180 210 90
Circle -16777216 true false 30 210 90
Polygon -16777216 true false 162 110 132 108 134 165 209 165 194 135 189 126 180 119
Circle -7500403 true true 47 225 58
Circle -7500403 true true 195 225 58

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

sheep-rot
true
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

star-rot
true
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

link2
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Polygon -7500403 true true 90 60 150 0 210 60
@#$#@#$#@
1
@#$#@#$#@
