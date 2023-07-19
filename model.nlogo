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
