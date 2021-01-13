globals [
  action ;;last button pressed. left = 1, right = 2
  object-x ;;the object's current position
  object-y
  push-force
  total-push-force
  global-speed ;;for plotting @?
  global-d-speed

  win? ;;to see if they've won
  lost? ;;to see if they've lost (pushed the object over the edge)

  score
  last-score ;;for coding purposes, keeping track of the previous score (to see if it's changed)
  season
  timer-running?

  timer-at-end ;;timer at time of win/deaths

  nr-of-pushes
  distance-flyttet



  energy ;;the player's energy (keeping it in a global variable for now) @change this?

  mouse-was-down?
  mouse-dist ;;distance from mouse-down point to object
  mouse-acc
  old-mouse-x ;;keeping track of whether the mouse has been moved
  old-object-x ;;keeping track for mgraphics (mouse) purposes
  update-mgraphics?
  mouse-divisor
  mouse-on-object?
  mouse-pull-on?

  try-nr ;;@not used now ;;a nr starting at 0, goes up after each fail/win, used to name the list of saved values after each try
  save-list ;;the list storing saved values after each go


  a ;;acceleration
  v ;;velocity
  delta-v ;;velocity after friction is subtracted
  friktion ;;friktion
  s ;;displacement
  u ;;initial/current speed
  final-displacement ;;after scaling

  prev-push-force
  time-pushed

]

breed [houses house] ;;needs to be a breed only so it can be in the background layer
breed [explosions explosion]
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
  mass
  object-friction

  kinetisk-energi

  real-heading
  apparent-heading ;;only for fail animation
]

graphics-own [lifetime name]
mgraphics-own [lifetime name]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;KRÆFTER OG BEVÆGELSE;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all ;;but don't want to clear the global 'try-nr'?
  ;;clear-all-plots clear-ticks clear-turtles clear-patches clear-drawing clear-output ;;everything from clear-all except clear-globals (want to keep try-nr)

  set save-list []

  make-world ;;cliff and season also specified here
  make-object ;;sets up the chosen level that's chosen

  set object-x -26 ;;the object's starting position

  set win? false set lost? false
  set timer-running? false
  set nr-of-pushes 0
  set distance-flyttet 0

  set mouse-was-down? FALSE

  reset-ticks
end

to go
  every 3 / hastighed   [

    if count objects > 0 [
      set object-x [xcor] of one-of objects
      set object-y [ycor] of one-of objects] ;;there'll always only be one object at a time

    if not lost? and not win? [do-mouse-stuff]

    move-person
    if not lost? [check-object] ;;to see if they've failed
    if lost? [fail-animation] ;;animation of object falling down

    if not lost? and not win? [
      accelerate-object
      ask objects [set kinetisk-energi 0.5 * choose-mass * delta-v ^ 2] ;;kinetisk energi er en halv gange masse gange fart i anden
      check-win
      update-graphics
    ]

    ;;ask objects [if resistance > 0 [print resistance]] ;;@to check how it gets too high, need to add failsafe in resistance reporter

    ifelse mouse-xcor = object-x [set mouse-on-object? TRUE] [set mouse-on-object? FALSE] ;;@testing precision

    tick

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

  if mouse-down? and abs mouse-dist > 0 [ ;;to avoid division by 0

    ;;ADD THE ACCELERATION VECTOR BASED ON THE DISTANCE

    let scaling-mouse 1000 ;;@ testing size of scaling-mouse
    set mouse-divisor scaling-mouse / mouse-dist ;;/ scaling-mouse

    set mouse-acc (- (mouse-dist)^ 2 ) / mouse-divisor ;;proportionel med kvadratet på afstanden ;;(og så lineært skaleret ned)

    if mouse-xcor > object-x [set mouse-acc (mouse-acc)] ;;if pushing left, subtract push-force instead of adding it (negative speed = left)
  if mouse-xcor < object-x [set mouse-acc (- mouse-acc)]
  ]

  set push-force mouse-acc ;;push-force is used in accelerate-object

  set old-mouse-x mouse-xcor ;;to check next run through if mouse position has changed ;;@delete?
  set old-object-x object-x

  ] ;;END of if styring = mus
end



to accelerate-object
  ask objects [

  ;;tag højde for om de skubber over længere tid end bare et tick:
  ifelse push-force = prev-push-force
	   [set time-pushed time-pushed + tick-i-sekunder] ;;hvor mange sekunder de har skubbet med denne kraft (increasing if they hold down the key)
     [set time-pushed tick-i-sekunder] ;;hvis de ikke holder inde over længere tid

if push-force != 0 [print "" print word "time pushed: " time-pushed print word "push-force: " push-force
    output-print "" output-print word "time pushed: " time-pushed output-print word "push-force: " push-force
    ] ;;@for testing only
    ;;push-force = skubbekraften i Newton (positiv = mod højre, negativ = mod venstre)

;;1. Calculate acceleration
   if styring = "tastatur" [
      ifelse push-force = 0 [
        set a 0 ;;no acceleration if no push this tick
      ]
     [
      set a push-force / choose-mass ;a = F/m ;;acceleration = Force / mass ;;push-force positive if going right, negative if going left ;;@acceleration can be 'negative' (to the left)
      ]
    ]

   if styring = "mus" [
      ifelse push-force = 0 [
        set a 0 ;;no acceleration if no mouse pull this tick
      ]
      [
        set a push-force / choose-mass ;;a = F/m ;;@CHECK IN DO-MOUSE-STUFF THAT THIS IS IN NEWTON
      ]
    ]

if a != 0 [print word "acceleration: " a output-print word "acceleration: " a] ;;@for testing only


;;2. Calculate new velocity
    set u [speed] of one-of objects ;;u = initial/current speed ;;(only ever one object at a time)

    set v u + ( a * time-pushed )  ;;v = u + a*t ;;velociy = initial speed + acceleration * time force is applied

    ;;MEN PGA t:
    ;;@^^så bliver det vel afgørende, hvor fine grained vi er/hvor tit vi tjekker Newton applied?! ;;skal det ændres, så hvis de holder inde, ændres t...?

         ;;if no acceleration, v = u (new speed = initial speed)
         ;;@velocity can be 'negative' (to the left)

if v != 0 [print word "velocity: " v output-print word "velocity: " v] ;;@for testing only


;;3. Calculate friction
    ifelse season = "sommer"
      [set friktion gnidnings-kof * normalkraft] ;;friktion = my * normalkraft ;;enhed: Newton
      [set friktion 0]


;;if v != 0 [print word "friktion: " friktion output-print word "friktion: " friktion]

    ;;@hvad med forskellen på statisk og dynamisk friktion? ;;to forskellige gnidningskoefficienter?!

    set delta-v v ;;for the case where there's no friction (delta-v used in step 4)


    ;;@SKUBBET SKAL FØRST STARTE, HVIS DENNE FRIKTIONS-VEKTOR OVERKOMMES
    ;;@^^så bliver det vel afgørende, hvor fine grained vi er/hvor tit vi tjekker Newton applied?! ;;skal det ændres, så hvis de holder inde, ændres t...?

    ifelse abs delta-v > friktion [ ;;hvis skubbekraften overstiger friktionskraften
    if v > 0 [set delta-v (v - friktion)] ;;if currently going right, friction towards left
    if v < 0 [set delta-v (v + friktion)] ;;if currently going left, friction towards right
    ]
    [
    set delta-v 0 ;;hvis skubbekraften IKKE overstiger friktionskraften
    ]


;;4. Calculate displacement
    ifelse a = 0 [
      set s delta-v * time-pushed ;;displacement = velocity * time (if no acceleration) ;;delta-v = velocity after friction is subtracted
    ]
    [
     ;;Calculate displacement given initial and final speeds ;;@MAYBE DON'T NEED THIS?! DO THIS? OR SIMPLY CALCULATE NEW VELOCITY, THEN DO s = v*t?
    ;;s = 1/2 * (u + v) * t ;;displacement = 1/2 * (initial speed + final speed) * time force is applied
    set s 0.5 * (u + delta-v) * time-pushed

if s > 0 [print word "s (displacement): " s output-print word "s (displacement): " s] ;;@for testing only

    ] ;;end of if a != 0


;;5. Move the object!
    set final-displacement s * patch-i-meter ;;s is displacement in meters ;;@right now without friction

if final-displacement > 0 [print word "final-displacement: " final-displacement output-print word "final-displacement: " final-displacement] ;;@for testing only

    forward final-displacement


    set distance-flyttet distance-flyttet + abs final-displacement
    set final-displacement 0 ;;@?


;;6. Reset/update variables
    set speed delta-v ;;the new calculated velocity (with friction subtracted), saved to object variable (and used as u in calculations next tick)
    set old-speed speed ;;the previous speed ;;object variable

    set prev-push-force push-force ;;save this push-force for next tick (to check if they keep holding it down)
    set total-push-force total-push-force + abs push-force ;;used to calculate arbejde
    set push-force 0 ;;reset the skubbekraft once it has been applied

    let lower-limit 0.05 ;;@can tweak this (since speed never quite reached 0)
    if speed < lower-limit and speed > 0 [set speed 0] ;;to the right
    if speed > (- lower-limit) and speed < 0 [set speed 0] ;;to the left

    set speed precision speed 5 ;;@precision can be tweaked
    set global-speed speed ;;plots continuously
    ;;if old-speed != speed [set global-speed speed] ;;for plotting only when the speed changes @?

    ] ;;END OF ASK OBJECTS


 ;;SPARKS animation
  if count objects > 0 and not lost? and object-y > min-pycor + 2 [ ask patch (object-x) (object-y - 2) [
    if (global-speed > 0 or global-speed < 0) and season != "vinter" [ ;;only if the object is moving and it's not winter (ice = 'no' friction)

    sprout-graphics 2 [
      set shape "star" set color yellow set size 0.7 set lifetime 0
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
  report abs total-push-force * distance-flyttet ;;A = F * s (enheder: joule = Newton * meter)
  ;;@check: is this right? både F og s er for skub i begge retninger
end


;;----------


;;to-report resistance ;;@substitute this with gnidningsmodstand?
  ;; minus resistance. The resistance depends on the speed (see the resistance reporter) ;;ACTUALLY SHOULDN'T DEPEND ON SPEED ?!
        ;;modstanden er proportionel med kvadratet på hastigheden (hvis man fordobler hastigheden, firedobler man modstanden) (?!)

  ;;let modstand-used modstand / 10
  ;;if season = "summer" [
    ;;report speed ^ 2 / (1 / (modstand-used)) ;;the higher modstand, the higher resistance
    ;;@add failsafe here, sometimes the number can still get too high for NetLogo (?)
  ;;]
  ;;if season = "winter" [
    ;;report 0
  ;;]
;;end

;;----------

to check-win
  ask houses [
    let win-patches (patch-set patch-here [neighbors] of patch-here)
    ask win-patches [
      let the-object one-of objects-here
      if the-object != nobody [
        if [speed < 0.03] of the-object [ ;;@ can change accuracy needed to win


          if styring = "mus" and not mouse-down? [set win? TRUE] ;;kan kun vinde, når museknappen løftes
          if styring = "tastatur" [set win? TRUE]
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
    ask objects [die]
    ask players [set shape "person-happy"]
    ask graphics [die] ask mgraphics [die] ;;to kill off any sparks and the elastic (if mouse control)
    ask patch (max-pxcor - (max-pxcor / 2) - 3) (max-pycor - 6) [set plabel (word "Sejt! Du brugte " (timer-at-end) " sekunder og " nr-of-pushes " skub.") ]
    ask patch (max-pxcor - (max-pxcor / 2) - 8) (max-pycor - 9) [set plabel "Fortsæt det gode arbejde!"]

    set timer-running? FALSE ;;so the timer can start over again with their next first push
    set global-speed 0 set global-d-speed 0
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



  ask graphics [ ;;the visual sparks
    forward 1
    set lifetime lifetime + 1
    if lifetime >= 2[die]
  ]
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

    ask patch (max-pxcor - (max-pxcor / 2) - 6) (max-pycor - 6) [set plabel (word "Åh nej, objektet faldt ud over kanten!") ]
    ask patch (max-pxcor - (max-pxcor / 2) - 9) (max-pycor - 9) [set plabel "Tryk på 'R' for at prøve igen!"]

      ;;user-message "You failed! :-( Try again!"
     ;;genstart ;;starts the level over
    ]
  ]
end



;;SAVING THE VALUES

to make-save-list
  ;;set save-list [] ;;@now overwritten after each go (if we've already sent previous lists to a server or something)? Or should all gos be saved?
  ;;set save-list lput (list "time" timer-at-end) save-list ;;nested list? (first = variable, second = value)

  set save-list lput (list level choose-mass skub nr-of-pushes distance-flyttet gnidnings-kof timer-at-end) save-list
    ;;level, objektets masse, kraft i hvert skub, antal skub, total distance, gnidningskoefficient, tid

  print save-list
  output-print save-list
end



;;;;;;;;;;;;;;;;;;;;;;;
;;;MOVING THE PLAYER;;;
;;;;;;;;;;;;;;;;;;;;;;;

to move-person
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
  ask players [
    ifelse object-x < max-pxcor - 1
        [setxy (object-x + 1) 0]
        [setxy max-pxcor 0]
    set shape "pushing-left"
  ]

  if not timer-running? [reset-timer] ;;if it's the very first push, start the timer
  set timer-running? TRUE

  set push-force (push-force - skub) ;;pushing to the left means negative push-force in these calculations (negative speed = going to the left)

  set nr-of-pushes nr-of-pushes + 1

  ;;check-object
end

to move-right
 ask players [
    ifelse object-x > min-pxcor + 1
        [setxy (object-x + -1) 0] ;;@
        [setxy min-pxcor 0]
    set shape "pushing-right"

    if xcor > (max-pxcor - 10) [set xcor (max-pxcor - 10)] ;;the player can't move over the edge
  ]

  if not timer-running? [reset-timer] ;;if it's the very first push, start the timer
  set timer-running? TRUE

  set push-force push-force + skub

  set nr-of-pushes nr-of-pushes + 1
  ;;check-object
end


;;;GRAPHICS;;;

to make-world
  ask players [die]
  ask objects [die]

  ifelse level = "testlevel 1" ;;add all the cliff-less levels here
    [set klippe? FALSE]
    [set klippe? TRUE]

  ifelse level = "testlevel 4" ;;add all the winter levels here
    [set season "vinter"]
    [set season "sommer"]


  if season = "sommer" [
  ask patches [ ;;summer sky and grass
    ifelse pycor > -2 or (pxcor > (max-pxcor - 10) and pycor > -19)  [set pcolor sky] [ set pcolor scale-color green ((random 500) + 5000) 0 9000 ] ;;summer
  ]
    if not klippe? [
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
    if not klippe? [
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
  ask patch (max-pxcor - (max-pxcor / 2) - 9) (max-pycor - 9) [set plabel ""]


;;;;;;;;;;
;;LEVELS;;
;;;;;;;;;;

  if level = "testlevel 1" [
    set klippe? FALSE ;;ingen afgrund
    create-objects 1 [
      set shape "sheep"
      set color white
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 5
    ]
  ]

  if level = "testlevel 2" [
    set klippe? TRUE ;;nu med afgrund (specified in make-world, not here (but kept here for overblik)
    create-objects 1 [
      set shape "sheep"
      set color white
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 5
    ]
  ]

  if level = "testlevel 3" [
    set klippe? TRUE ;;nu med afgrund (specified in make-world, not here (but kept here for overblik)
    create-objects 1 [
      set shape "push-car" ;;push-car is my modified non-floating shape (and has a rotatable push-car-rot shape for the fail animation)
      set color yellow
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 10
    ]
  ]

   if level = "testlevel 4" [
    set klippe? TRUE ;;nu med afgrund (specified in make-world, not here (but kept here for overblik)
    create-objects 1 [
      set shape "push-car" ;;push-car is my modified non-floating shape (and has a rotatable push-car-rot shape for the fail animation)
      set color yellow
      set size 3
      setxy (min-pxcor + 4) 0
      set heading 90
      set choose-mass 10
      ;;vinter ;;ADD THIS IN MAKE-WORLD - just here for overblik
    ]
  ]


  ;;@add more levels here
end

to genstart
  ask patch (max-pxcor - (max-pxcor / 2) - 8) (max-pycor - 5) [set plabel "" ]
  ask patch (max-pxcor - (max-pxcor / 2) - 13) (max-pycor - 8) [set plabel ""]

  make-object
  set win? FALSE set lost? FALSE
  ask players [setxy (min-pxcor + 1) 0 set shape "person"]
  set push-force 0
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
    report "Spillet kører ikke endnu"
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
220
10
960
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
45
125
115
158
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
120
125
183
158
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
850
520
915
553
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
920
520
985
553
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

INPUTBOX
215
520
290
580
choose-mass
5.0
1
0
Number

INPUTBOX
50
275
100
335
skub
140.0
1
0
Number

MONITOR
1060
10
1170
55
Objektets hastighed
min [speed] of objects
17
1
11

BUTTON
970
10
1025
43
Vinter
set season \"vinter\"\nmake-world\nmake-object
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
970
40
1025
73
Sommer
set season \"sommer\"\nmake-world\nmake-object
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
Objektets hastighed
NIL
NIL
0.0
10.0
0.0
0.4
true
false
"" ""
PENS
"Absolut hastighed" 1.0 0 -2674135 true "" "plot abs global-speed"

CHOOSER
70
75
162
120
level
level
"testlevel 1" "testlevel 2" "testlevel 3" "testlevel 4"
0

BUTTON
90
165
150
200
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
540
535
712
568
hastighed
hastighed
1
100
38.0
1
1
%
HORIZONTAL

MONITOR
980
215
1115
260
Timer
show-timer
17
1
11

MONITOR
970
155
1035
200
Antal skub
nr-of-pushes
17
1
11

SWITCH
25
10
115
43
klippe?
klippe?
1
1
-1000

CHOOSER
120
10
212
55
styring
styring
"mus" "tastatur"
1

SLIDER
50
240
195
273
modstand
modstand
0.1
5
1.5
.1
1
NIL
HORIZONTAL

TEXTBOX
35
225
200
251
modstand kun hvis det er sommer
11
0.0
1

MONITOR
1240
215
1420
260
Kinetisk energi
min [kinetisk-energi] of objects
17
1
11

TEXTBOX
1230
265
1440
291
kinetisk energi = 0.5 * mass * velocity^2
11
0.0
1

MONITOR
425
560
535
605
Bevægelsesafstand
object-x + 26
2
1
11

TEXTBOX
590
520
675
538
Spillets hastighed
11
0.0
1

TEXTBOX
795
560
1055
591
Tryk på \"J\" og \"L\" piletasterne for at styre
14
0.0
1

TEXTBOX
105
295
175
346
størrelsen på skubbet (i N)
11
0.0
1

TEXTBOX
225
580
295
621
objektets masse (i kg)
11
0.0
1

TEXTBOX
110
215
155
233
TESTER:
11
0.0
1

INPUTBOX
30
415
105
475
g
9.82
1
0
Number

INPUTBOX
115
415
190
475
gnidnings-kof
0.36
1
0
Number

TEXTBOX
120
475
215
516
my = ca 0.36 for gummi mod græs (ingen enhed)
11
0.0
1

INPUTBOX
25
525
105
585
patch-i-meter
0.25
1
0
Number

INPUTBOX
115
525
195
585
tick-i-sekunder
1.0
1
0
Number

TEXTBOX
40
480
120
506
(m / s^2)
11
0.0
1

MONITOR
430
515
527
560
afstand-i-meter
(object-x + 26) * patch-i-meter
17
1
11

TEXTBOX
60
385
210
403
joule = Newton * meter
11
0.0
1

MONITOR
970
100
1027
145
NIL
try-nr
17
1
11

MONITOR
1060
55
1117
100
NIL
a
17
1
11

MONITOR
1115
55
1172
100
NIL
s
17
1
11

MONITOR
350
525
407
570
NIL
friktion
17
1
11

MONITOR
1060
100
1157
145
NIL
distance-flyttet
17
1
11

OUTPUT
1180
10
1495
175
11

TEXTBOX
25
340
230
366
@BRUGES IKKE I MUSE-STYRING
11
0.0
1

MONITOR
1085
145
1142
190
NIL
arbejde
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
