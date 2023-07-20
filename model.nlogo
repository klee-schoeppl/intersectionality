extensions[Nw array]
globals[L M]

breed[OCs OC] ;orange circles
breed[BCs BC] ;blue circles
breed[OSs OS] ;orange stars
breed[BSs BS] ;blue stars

undirected-link-breed[inLinks inLink] ;links with agents of the same color and shape
undirected-link-breed[outLinksColor outLinkColor] ;with the same shape, but of different color
undirected-link-breed[outLinksShape outLinkShape] ;with the same color, but of different shape
undirected-link-breed[outLinks outLink] ;with different color and shape

links-own[fairness] ;is this collaboration fair? If no, who discriminates?


turtles-own[
  mSelf mOut mOutshape mOutColor ;productivity multipliers
  strategyIn strategyOut strategyOutColor strategyOutShape ;current strategies of this agent
  payoffsIn payoffsOut payoffsOutColor payoffsOutShape ;(potential) payoffs of each strategy in the last round
  energy ;actual payoff from the last game
]

;runs once as the simulation starts
to setup
  clear-all
  set M 5
  set L (10 - H)
  setupAgents
  if mode = "Fixed network" [setupNetwork]
  reset-ticks
end

;runs once per tick/ round
to go
  ifelse ticks >= maxTicks [stop][tick]
  play

  ;mode decides what gets updated
  (ifelse mode = "Fixed network" [
    ask turtles [
      let i random-float 1
      if i < updateChance [updateStrategies]
    ]
  ] mode = "Fixed strategies"[
    ask one-of turtles [updateNetwork]
  ][
    ask turtles [
      let i random-float 1
      let j random-float 1
      if i < updateChance AND j < 0.5 [updateStrategies]
      if i < updateChance AND j > 0.5 [updateNetwork]
    ]
  ])
  checkLinks
end

;each group of agents is initialized separately
to setupAgents

  create-OCs sizeOC[
    set color orange
    set shape "circle"
    set mSelf mOrange * mCircle
    set mOut (mSelf + mBlue * mStar) / 2
    set mOutColor (mSelf + mBlue * mCircle) / 2
    set mOutShape (mSelf + mOrange * mStar) / 2
    if mode = "Fixed strategies" [
      set strategyIn 1
      (ifelse
        OC-BC = "OC > BC" [set strategyOutColor 2]
        OC-BC = "OC < BC" [set strategyOutColor 0]
        [set strategyOutColor 1]
      )
      (ifelse
        OC-OS = "OC > OS" [set strategyOutShape 2]
        OC-OS = "OC < OS" [set strategyOutShape 0]
        [set strategyOutShape 1]
      )
      (ifelse
        OC-BS = "OC > BS" [set strategyOut 2]
        OC-BS = "OC < BS" [set strategyOut 0]
        [set strategyOut 1]
      )
    ]
  ]

  create-OSs sizeOS[
    set color orange
    set shape "star"
    set mSelf mOrange * mStar
    set mOut (mSelf + mBlue * mCircle) / 2
    set mOutColor (mSelf + mBlue * mStar) / 2
    set mOutShape (mSelf + mOrange * mCircle) / 2
    if mode = "Fixed strategies" [
      set strategyIn 1
      (ifelse
        OS-BS = "OS > BS" [set strategyOutColor 2]
        OS-BS = "OS < BS" [set strategyOutColor 0]
        [set strategyOutColor 1]
      )
      (ifelse
        OC-OS = "OC < OS" [set strategyOutShape 2]
        OC-OS = "OC > OS" [set strategyOutShape 0]
        [set strategyOutShape 1]
      )
      (ifelse
        BC-OS = "BC < OS" [set strategyOut 2]
        BC-OS = "BC > OS" [set strategyOut 0]
        [set strategyOut 1]
      )
    ]
  ]

  create-BSs sizeBS[
    set color blue
    set shape "star"
    set mSelf mBlue * mStar
    set mOut (mSelf + mOrange * mCircle) / 2
    set mOutColor (mSelf + mOrange * mStar) / 2
    set mOutShape (mSelf + mBlue * mCircle) / 2
    if mode = "Fixed strategies" [
      set strategyIn 1
      (ifelse
        OS-BS = "OS < BS" [set strategyOutColor 2]
        OS-BS = "OS > BS" [set strategyOutColor 0]
        [set strategyOutColor 1]
      )
      (ifelse
        BC-BS = "BC < BS" [set strategyOutShape 2]
        BC-BS = "BC > BS" [set strategyOutShape 0]
        [set strategyOutShape 1]
      )
      (ifelse
        OC-BS = "OC < BS" [set strategyOut 2]
        OC-BS = "OC > BS" [set strategyOut 0]
        [set strategyOut 1]
      )
    ]
  ]

  create-BCs sizeBC[
    set color blue
    set shape "circle"
    set mSelf mBlue * mCircle
    set mOut (mSelf + mOrange * mStar) / 2
    set mOutColor (mSelf + mOrange * mCircle) / 2
    set mOutShape (mSelf + mBlue * mStar) / 2
    if mode = "Fixed strategies" [
      set strategyIn 1
      (ifelse
        OC-BC = "OC < BC" [set strategyOutColor 2]
        OC-BC = "OC > BC" [set strategyOutColor 0]
        [set strategyOutColor 1]
      )
      (ifelse
        BC-BS = "BC > BS" [set strategyOutShape 2]
        BC-BS = "BC < BS" [set strategyOutShape 0]
        [set strategyOutShape 1]
      )
      (ifelse
        BC-OS = "BC > OS" [set strategyOut 2]
        BC-OS = "BC < OS" [set strategyOut 0]
        [set strategyOut 1]
      )
    ]
  ]

  ;all agents are placed in a random position of the world, initialized with empty payoff lists
  ;if strategies are to be updated, they also start with random demands for each group
  ask turtles[
    set xcor random-xcor
    set ycor random-ycor
    set payoffsIn array:from-list (list 0 0 0)
    set payoffsOut array:from-list (list 0 0 0)
    set payoffsOutColor array:from-list (list 0 0 0)
    set payoffsOutShape array:from-list (list 0 0 0)
    if mode != "Fixed strategies"[
      set strategyIn random 3
      set strategyOutColor random 3
      set strategyOut random 3
      set strategyOutShape random 3
    ]
  ]
end

;creates a network based on pIn and pOut for both shape and color
to setupNetwork
  ask turtles[
    ask other turtles[
      let i random-float 1
      if color = [color] of myself AND shape = [shape] of myself AND (i > (1 - pInColor) * (1 - pInShape))[
       createLink myself self
      ]
      if color = [color] of myself AND shape != [shape] of myself AND (i > (1 - pInColor) * (1 - pOutShape))[
        createLink myself self
      ]
      if color != [color] of myself AND shape = [shape] of myself AND (i > (1 - pOutColor) * (1 - pInShape))[
         createLink myself self
      ]
      if color != [color] of myself AND shape != [shape] of myself AND (i > (1 - pOutColor) * (1 - pOutShape))[
        createLink myself self
      ]
    ]
  ]

  ;checks whether the just created network is connected
  let pathCheck true
  ask turtles[
    ask other turtles[
      if nw:path-to myself = false [set pathCheck false]
    ]
  ]
  print (word "It is " pathCheck " that there are paths between any two agents.")
  if (pathCheck = false AND requireConnectedGraph = true) [
  print "Because the settings require a connected graph, the network will now be regenerated."
  setupNetwork
  ]

  checkLinks
end

;categorizes each individual link as fair or discriminatory
to checkLinks
  ask inlinks [
    let i 0
    ask both-ends [set i i + strategyIn]
    ifelse i = 2 * [strategyIn] of one-of both-ends [set fairness "fair"][set fairness "unfair"]
  ]

  ask outLinksColor [
    let i [strategyOutColor] of one-of both-ends with [color = orange]
    let j [strategyOutColor] of one-of both-ends with [color = blue]
    if i = j [set fairness "fair"]
    if i > j [set fairness "Orange discriminates"] ;and i = 2
    if i < j [set fairness "Blue discriminates"]
  ]

  ask outLinksShape [
    let i [strategyOutShape] of one-of both-ends with [shape = "circle"]
    let j [strategyOutShape] of one-of both-ends with [shape = "star"]
    if i = j [set fairness "fair"]
    if i > j [set fairness "Circle discriminates"]
    if i < j [set fairness "Star discriminates"]
  ]

  ask outLinks[
    ifelse any? both-ends with [shape = "circle" and color = orange][
      let i [strategyOut] of one-of both-ends with [shape = "circle"]
      let j [strategyOut] of one-of both-ends with [shape = "star"]

      if i = j [set fairness "fair"]
      if i > j [set fairness "Orange circle discriminates"]
      if i < j [set fairness "Blue star discriminates"]
    ][
      let i [strategyOut] of one-of both-ends with [shape = "circle"]
      let j [strategyOut] of one-of both-ends with [shape = "star"]
      if i = j [set fairness "fair"]
      if i > j [set fairness "Blue circle discriminates"]
      if i < j [set fairness "Orange star discriminates"]
    ]
  ]
end

;determines the (potential) payoff for each agent for each strategy
to play
  ask turtles[
    ;determines the payoffs for each of the 12 combinations of links and strategies
    array:set payoffsIn 0 ((count inLink-neighbors) * L * mSelf)
    array:set payoffsIn 1 (count inLink-neighbors with [strategyIn < 2] * M * mSelf)
    array:set payoffsIn 2 (count inLink-neighbors with [strategyIn < 1] * H * mSelf)

    array:set payoffsOutColor 0 (count outLinkColor-neighbors * L * mOutColor)
    array:set payoffsOutColor 1 (count outLinkColor-neighbors with [strategyOutColor < 2] * M * mOutColor)
    array:set payoffsOutColor 2 ((count outLinkColor-neighbors with [strategyOutColor < 1]) * H * mOutColor)

    array:set payoffsOutShape 0 (count outLinkShape-neighbors * L * mOutShape)
    array:set payoffsOutShape 1 (count outLinkShape-neighbors with [strategyOutShape < 2] * M * mOutShape)
    array:set payoffsOutShape 2 (count outLinkShape-neighbors with [strategyOutShape < 1] * H * mOutShape)

    array:set payoffsOut 0 (count outLink-neighbors * L * mOut)
    array:set payoffsOut 1 (count outLink-neighbors with [strategyOut < 2] * M * mOut)
    array:set payoffsOut 2 (count outLink-neighbors with [strategyOut < 1] * H * mOut)

    ;determine the energy (or actual payoff) based on the strategies played
    set energy (array:item payoffsIn strategyIn
      + array:item payoffsOut strategyOut
      + array:item payoffsOutShape strategyOutShape
      + array:item payoffsOutColor strategyOutColor)
   ]
end

;the agent updates their strategies to those that would have given biggest payoffs this round
to updateStrategies
  if count inLink-neighbors > 0 [set strategyIn rndMaxIndex array:to-list payoffsIn]
  if count outLinkShape-neighbors > 0 [set strategyOutShape rndMaxIndex array:to-list payoffsOutShape]
  if count outLinkColor-neighbors > 0 [set strategyOutColor rndMaxIndex array:to-list payoffsOutColor]
  if count outLink-neighbors > 0 [set strategyOut rndMaxIndex array:to-list payoffsOut]
end

;follows the (somewhat contrived) procedure for network updates as described by Rubin & O'Connor
to updateNetwork

  let agent1 self
  let agent2 one-of turtles with [who != [who] of agent1]
  let agent3 one-of turtles with [who != [who] of agent2 and who != [who] of agent1]

  let i count link-neighbors
  while [[who] of agent1 = [who] of agent2][
    set agent2 one-of other turtles
  ]

  ask agent2[
    let j count link-neighbors

    let payoff1 determinePayoff agent1 agent2
    let payoff2 determinePayoff agent2 agent1
    let currentPayoff1 item 0 worstLink agent1
    let currentPayoff2 item 0 worstLink agent2
    let worthIt1 payoff1 > currentPayoff1
    let worthIt2 payoff2 > currentPayoff2

    ifelse link-neighbor? agent1 [
      ;This is what heppens if active and passive agents are already collaborating
      ask agent1 [
        ask agent3[
          let k count link-neighbors
          let payoff3 determinePayoff agent3 agent1
          let currentPayoff3 item 0 worstLink agent3

          set worthIt1 determinePayoff agent1 agent2 < determinePayoff agent1 agent3
          let worthIt3 payoff3 > currentPayoff3

          if i < maxLinks and k < maxLinks [createLink agent1 agent3]
          if i = maxLinks and k < maxLinks and worthIt1 [
            ask agent1 [ask link-with agent2 [die]]
            createLink agent1 agent3
          ]
          if i < maxLinks and k = maxLinks and worthIt3 [
            ask item 1 worstLink agent3 [die]
            createLink agent1 agent3
          ]
          if i = maxLinks and k = maxLinks and worthIt1 and worthIt3 [
            ask agent1 [ask link-with agent2 [die]]
            ask item 1 worstLink agent3 [die]
            createLink agent1 agent3
          ]
        ]
      ]
    ][
    ;This happens when the active and passive agents are not yet collaborators
      if i < maxLinks and j < maxLinks [createLink agent1 agent2]
      if i = maxLinks and j < maxLinks and worthIt1 [
        ask item 1 worstLink agent1 [die]
        createLink agent1 agent2
      ]
      if i < maxLinks and j = maxLinks and worthIt2 [
        ask item 1 worstLink agent2 [die]
        createLink agent1 agent2
      ]
      if i = maxLinks and j = maxLinks and worthIt1 and worthIt2 [
        ask item 1 worstLink agent1 [die]
        ask item 1 worstLink agent2 [die]
        createLink agent1 agent2
      ]
    ]
  ]
end

;reports the payoff a link with agent2 has/ would have for agent1
to-report determinePayoff [agent1 agent2]
  let strategy1 0
  let strategy2 0
  let result 0
  (ifelse
    [color] of agent1 = [color] of agent2 AND [shape] of agent1 = [shape] of agent2 [
      set strategy1 [strategyIn] of agent1
      set strategy2 [strategyIn] of agent2
    ]
    [color] of agent1 = [color] of agent2 AND [shape] of agent1 != [shape] of agent2[
      set strategy1 [strategyOutShape] of agent1
      set strategy2 [strategyOutShape] of agent2
    ]
    [color] of agent1 != [color] of agent2 AND [shape] of agent1 = [shape] of agent2[
      set strategy1 [strategyOutColor] of agent1
      set strategy2 [strategyOutColor] of agent2
    ][
      set strategy1 [strategyOut] of agent1
      set strategy2 [strategyOut] of agent2
    ]
  )
  if strategy1 = 0 [set result L]
  if strategy1 = 1 and strategy2 < 2 [set result M]
  if strategy1 = 2 and strategy2 < 1 [set result H]

  report result * ([mSelf] of agent1 + [mSelf] of agent2) / 2
end

;reports the agent's link with the lowest payoff
to-report worstLink [agent]
  let utility 100000 ;arbitrarily high value to be counted down
  let myWorstLink one-of my-links
  ask agent[
    ask my-links [
      if utility > determinePayoff myself other-end[
        set utility determinePayoff myself other-end
        set myWorstLink self
      ]
    ]
  ]
  report (list utility myWorstLink)
end

;creates the right kind of link between two agents, in terms of breed, color and shape
to createLink [agent1 agent2]
  ask agent1 [
    ask agent2 [
      (ifelse
        [color] of agent1 = [color] of agent2 AND [shape] of agent1 = [shape] of agent2 [
          create-inLink-with myself
          ask link-with myself [
            set color [color] of myself
            set shape [shape] of myself
          ]
        ]
        [color] of agent1 = [color] of agent2 AND [shape] of agent1 != [shape] of agent2[
          create-outLinkShape-with myself
           ask link-with myself [
            set color [color] of myself
            set shape "default"
          ]
        ]
        [color] of agent1 != [color] of agent2 AND [shape] of agent1 = [shape] of agent2[
          create-outLinkColor-with myself
           ask link-with myself [
            set color white
            set shape [shape] of myself
          ]
        ][
         create-outLink-with myself
           ask link-with myself [
            set color white
            set shape "default"
          ]
        ]
      )
    ]
  ]
end

;reports a random index of the maximum value in a list (unlike the max function)
to-report rndMaxIndex [input]
  let maxValue max input
  let indices n-values length input [ ? -> ifelse-value (item ? input = maxValue) [?][false]]
  let results filter [i -> i != false] indices
  report one-of results
end







@#$#@#$#@
GRAPHICS-WINDOW
12
10
522
521
-1
-1
15.212121212121213
1
10
1
1
1
0
0
0
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
204
534
277
567
NIL
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
288
534
351
567
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
525
808
697
841
sizeOC
sizeOC
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
700
842
872
875
sizeBS
sizeBS
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
525
673
697
706
pInColor
pInColor
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
526
711
698
744
pOutColor
pOutColor
0
1
0.01
0.01
1
NIL
HORIZONTAL

SWITCH
37
595
238
628
requireConnectedGraph
requireConnectedGraph
0
1
-1000

SLIDER
241
595
414
628
H
H
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
212
633
385
666
updateChance
updateChance
0
1
0.1
0.05
1
NIL
HORIZONTAL

BUTTON
355
534
419
568
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

PLOT
527
10
968
434
Link fainess
ticks
Percentage of all links
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Fair inlinks" 1.0 0 -7500403 true "" "if count inlinks with [fairness = \"fair\"] > 0 [plot (count inlinks with [fairness = \"fair\"]) / count links * 100]"
"Fair outlinks" 1.0 0 -10899396 true "" "if count links with [breed != inlinks AND fairness = \"fair\"] > 0 [plot (count links with [breed != inlinks AND fairness = \"fair\"]) / count links * 100]"
"Unfair outlinks" 1.0 0 -2674135 true "" "if count Links > 0 [plot (count Links with [fairness != \"fair\" AND breed != inlinks]) / count links * 100]"
"Unfair inlinks" 1.0 0 -8630108 true "" "if count inlinks with [fairness = \"unfair\"] > 0 [plot (count inlinks with [fairness = \"unfair\"]) / count links * 100]"

CHOOSER
29
527
195
572
Mode
Mode
"Fixed network" "Fixed strategies" "Dynamic"
0

SLIDER
36
633
209
666
maxLinks
maxLinks
1
50
3.0
1
1
NIL
HORIZONTAL

PLOT
971
10
1472
435
Linkcounts
Ticks
Links
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Between Colors" 1.0 0 -7500403 true "" "plot count links with [color = white]"
"Within Orange" 1.0 0 -955883 true "" "plot count links with [color = orange]"
"Within Blue" 1.0 0 -13345367 true "" "plot count Links with [color = blue]"
"Within Circles" 1.0 0 -5825686 true "" "plot count Links with [shape = \"circle\"]"
"Within Stars" 1.0 0 -2674135 true "" "plot count Links with [shape = \"star\"]"
"Between Shapes" 1.0 0 -6459832 true "" "plot count Links with [shape = \"default\"]"
"Proper outlinks" 1.0 0 -13840069 true "" "plot count outlinks"

INPUTBOX
36
676
197
736
maxTicks
100.0
1
0
Number

SLIDER
701
673
873
706
pInShape
pInShape
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
699
807
871
840
sizeOS
sizeOS
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
525
842
697
875
sizeBC
sizeBC
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
701
711
874
744
pOutShape
pOutShape
0.00
1
0.01
0.01
1
NIL
HORIZONTAL

TEXTBOX
191
756
341
774
Strategy fairness
12
0.0
0

CHOOSER
35
781
173
826
OC-OS
OC-OS
"OC > OS" "OC < OS" "OC = OS"
0

CHOOSER
176
781
314
826
OC-BC
OC-BC
"OC > BC" "OC < BC" "OC = BC"
2

CHOOSER
316
781
454
826
OC-BS
OC-BS
"OC > BS" "OC < BS" "OC = BS"
0

CHOOSER
35
828
173
873
BC-OS
BC-OS
"BC > OS" "BC < OS" "BC = OS"
0

CHOOSER
176
828
314
873
BC-BS
BC-BS
"BC > BS" "BC < BS" "BC = BS"
0

CHOOSER
316
828
454
873
OS-BS
OS-BS
"OS > BS" "OS < BS" "OS = BS"
0

PLOT
1475
10
1917
435
Energy
ticks
Mean energy per group
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Orange circles" 1.0 0 -955883 true "" "let i 0\nask OCs[ set i i + energy]\nplot i / count OCs"
"Orange stars" 1.0 0 -10899396 true "" "let i 0\nask OSs[ set i i + energy]\nplot i / count OSs"
"Blue circles" 1.0 0 -13345367 true "" "let i 0\nask BCs[ set i i + energy]\nplot i / count BCs"
"Blue stars" 1.0 0 -2064490 true "" "let i 0\nask BSs[ set i i + energy]\nplot i / count BSs"

PLOT
968
438
1286
712
OC-OS
ticks
Percentage of links
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"OC > OS" 1.0 0 -2674135 true "" "let i 0\nlet j 0\nask OCs [ \nask my-outLinksShape[\n  set i i + 1\n  if fairness = \"Circle discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OC < OS" 1.0 0 -10899396 true "" "let i 0\nlet j 0\nask OCs [\nask my-outLinksShape[\n  set i i + 1\n  if fairness = \"Star discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OC = OS" 1.0 0 -7500403 true "" "let i 0\nlet j 0\nask OCs[ask my-outlinksShape[\nset i i + 1\n  if fairness = \"fair\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"

PLOT
1288
438
1607
712
OC-BC
ticks
Percentage of links
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"OC > BC" 1.0 0 -2674135 true "" "let i 0\nlet j 0\nask OCs [ \nask my-outLinksColor[\n  set i i + 1\n  if fairness = \"Orange discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OC < BC" 1.0 0 -10899396 true "" "let i 0\nlet j 0\nask OCs [ \nask my-outLinksColor[\n  set i i + 1\n  if fairness = \"Blue discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OC = BC" 1.0 0 -7500403 true "" "let i 0\nlet j 0\nask OCs [ \nask my-outLinksColor[\n  set i i + 1\n  if fairness = \"fair\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"

PLOT
1610
438
1918
712
OC-BS
ticks
Percentage of links
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"OC > BS" 1.0 0 -2674135 true "" "let i 0\nlet j 0\nask OCs [ \nask my-outLinks[\n  set i i + 1\n  if fairness = \"Orange circle discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OC < BS" 1.0 0 -10899396 true "" "let i 0\nlet j 0\nask OCs [ \nask my-outLinks[\n  set i i + 1\n  if fairness = \"Blue star discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OC = BS" 1.0 0 -7500403 true "" "let i 0\nlet j 0\nask OCs [ \nask my-outLinks[\n  set i i + 1\n  if fairness = \"fair\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"

PLOT
968
714
1286
989
BC-OS
ticks
Percentage of links
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"BC > OS" 1.0 0 -2674135 true "" "let i 0\nlet j 0\nask BCs [ \nask my-outLinks[\n  set i i + 1\n  if fairness = \"Blue circle discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"BC < OS" 1.0 0 -10899396 true "" "let i 0\nlet j 0\nask BCs [ \nask my-outLinks[\n  set i i + 1\n  if fairness = \"Orange star discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"BC = OS" 1.0 0 -7500403 true "" "let i 0\nlet j 0\nask BCs [ \nask my-outLinks[\n  set i i + 1\n  if fairness = \"fair\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"

PLOT
1288
714
1608
990
BC-BS
ticks
Percentage of links
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"BC > BS" 1.0 0 -2674135 true "" "let i 0\nlet j 0\nask BCs [ \nask my-outLinksShape[\n  set i i + 1\n  if fairness = \"Circle discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"BC < BS" 1.0 0 -10899396 true "" "let i 0\nlet j 0\nask BCs [ \nask my-outLinksShape[\n  set i i + 1\n  if fairness = \"Star discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"BC = BS" 1.0 0 -7500403 true "" "let i 0\nlet j 0\nask BCs [ \nask my-outLinksShape[\n  set i i + 1\n  if fairness = \"fair\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"

PLOT
1610
714
1919
990
OS-BS
ticks
Percentage of links
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"OS > BS" 1.0 0 -2674135 true "" "let i 0\nlet j 0\nask OSs [ \nask my-outLinksColor[\n  set i i + 1\n  if fairness = \"Orange discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OS < BS" 1.0 0 -10899396 true "" "let i 0\nlet j 0\nask OSs [ \nask my-outLinksColor[\n  set i i + 1\n  if fairness = \"Blue discriminates\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"
"OS = BS" 1.0 0 -7500403 true "" "let i 0\nlet j 0\nask OSs [ \nask my-outLinksColor[\n  set i i + 1\n  if fairness = \"fair\" [set j j + 1]\n ]\n]\nif i > 0 [plot j / i * 100]\n"

SLIDER
528
534
703
567
mBlue
mBlue
1
2
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
529
569
702
602
mCircle
mCircle
1
2
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
706
534
879
567
mOrange
mOrange
1
2
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
706
569
879
602
mStar
mStar
1
2
2.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
638
508
788
526
Productivity multipliers
12
0.0
1

TEXTBOX
618
647
814
677
Probabilities of forming links
12
0.0
1

TEXTBOX
657
783
807
801
Group sizes
12
0.0
1

SLIDER
489
886
661
919
perO
perO
0.1
1
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
733
890
905
923
totalA
totalA
0
100
100.0
1
1
NIL
HORIZONTAL

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="FixedNetworkRecreation" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count links with [breed != inlinks AND fairness = "Blue discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "Orange discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "fair"]</metric>
    <enumeratedValueSet variable="OC-BC">
      <value value="&quot;OC &gt; OB&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;Fixed network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mCircle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS-BS">
      <value value="&quot;OS &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BS">
      <value value="&quot;OC &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perO">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="totalA">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-OS">
      <value value="&quot;BC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOC">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="requireConnectedGraph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mOrange">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTicks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxLinks">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mBlue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-OS">
      <value value="&quot;OC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBC">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="updateChance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mStar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-BS">
      <value value="&quot;BC &gt; BS&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count links with [breed != inlinks AND fairness = "Blue discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "Orange discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "fair"]</metric>
    <enumeratedValueSet variable="OC-BC">
      <value value="&quot;OC &gt; OB&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;Fixed network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mCircle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS-BS">
      <value value="&quot;OS &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BS">
      <value value="&quot;OC &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perO">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="totalA">
      <value value="20"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-OS">
      <value value="&quot;BC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOC">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="requireConnectedGraph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mOrange">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTicks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxLinks">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBC">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-OS">
      <value value="&quot;OC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mBlue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="updateChance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mStar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-BS">
      <value value="&quot;BC &gt; BS&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count links with [breed != inlinks AND fairness = "Blue discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "Orange discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "fair"]</metric>
    <enumeratedValueSet variable="perO">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BC">
      <value value="&quot;OC &gt; OB&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;Fixed network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mCircle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS-BS">
      <value value="&quot;OS &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BS">
      <value value="&quot;OC &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="totalA">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-OS">
      <value value="&quot;BC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOC">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="requireConnectedGraph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mOrange">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTicks">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxLinks">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mBlue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-OS">
      <value value="&quot;OC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBC">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="updateChance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mStar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-BS">
      <value value="&quot;BC &gt; BS&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentEnergy" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>eOC</metric>
    <metric>eOS</metric>
    <metric>eBC</metric>
    <metric>eBS</metric>
    <enumeratedValueSet variable="OC-BC">
      <value value="&quot;OC &gt; OB&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;Fixed network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBS">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mCircle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS-BS">
      <value value="&quot;OS &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BS">
      <value value="&quot;OC &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInColor">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perO">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="totalA">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-OS">
      <value value="&quot;BC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInShape">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOC">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="requireConnectedGraph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mOrange">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTicks">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOS">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutColor">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxLinks">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBC">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-OS">
      <value value="&quot;OC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mBlue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutShape">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="updateChance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mStar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-BS">
      <value value="&quot;BC &gt; BS&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="OC-BC">
      <value value="&quot;OC &gt; BC&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;Dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mCircle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS-BS">
      <value value="&quot;OS &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BS">
      <value value="&quot;OC &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-OS">
      <value value="&quot;BC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOC">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="requireConnectedGraph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mOrange">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTicks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxLinks">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBC">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-OS">
      <value value="&quot;OC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mBlue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="updateChance">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mStar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-BS">
      <value value="&quot;BC &gt; BS&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Dynamics" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count links with [breed != inlinks AND fairness = "Blue discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "Orange discriminates"]</metric>
    <metric>count links with [breed != inlinks AND fairness = "fair"]</metric>
    <enumeratedValueSet variable="OC-BC">
      <value value="&quot;OC &gt; BC&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;Dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mCircle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS-BS">
      <value value="&quot;OS &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BS">
      <value value="&quot;OC &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perO">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="totalA">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-OS">
      <value value="&quot;BC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOC">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="requireConnectedGraph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mOrange">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTicks">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOS">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutColor">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxLinks">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBC">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-OS">
      <value value="&quot;OC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mBlue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutShape">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="updateChance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mStar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-BS">
      <value value="&quot;BC &gt; BS&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="intersecFixedNetwork" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>eOC</metric>
    <metric>eOS</metric>
    <metric>eBC</metric>
    <metric>eBS</metric>
    <metric>disOC</metric>
    <metric>disOS</metric>
    <metric>disBC</metric>
    <metric>disBS</metric>
    <enumeratedValueSet variable="OC-BC">
      <value value="&quot;OC = BC&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mode">
      <value value="&quot;Fixed network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBS">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mCircle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OS-BS">
      <value value="&quot;OS &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-BS">
      <value value="&quot;OC &gt; BS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInColor">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perO">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="totalA">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-OS">
      <value value="&quot;BC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInShape">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOC">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="requireConnectedGraph">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mOrange">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTicks">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeOS">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutColor">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxLinks">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sizeBC">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OC-OS">
      <value value="&quot;OC &gt; OS&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mBlue">
      <value value="1"/>
      <value value="1.5"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pOutShape">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="H">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="updateChance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mStar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BC-BS">
      <value value="&quot;BC &gt; BS&quot;"/>
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

circle
0.0
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

star
0.0
-0.2 0 0.0 1.0
0.0 1 2.0 2.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
