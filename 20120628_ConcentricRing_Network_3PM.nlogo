turtles-own [tier orgID parentOrg weight reliability]

globals [orgStructure currentRing lastRing System_Weight System_Reliability nextTier Total_teams] ; Accretion defined in GUI

to Start
  clear-all
  set lastRing []         ; Initialize the global to empty list.
  set currentRing []
  crt 1 [set orgID who    ; Create the topmost turtle.
         set shape "circle"
         set lastRing fput who lastRing
         ]
  read_ConfigFile         ; to get specifications: radius, # of teams & # of subteams.
  build_Organization      ; by stepping trhough specs and creating teams and links

  generate_Random_Weights ; at last ring of the organization
  rollUp_Weights

;  clear-all
;  set lastRing []         ; Initialize the global to empty list.
;  set currentRing []
;  crt 1 [set orgID who    ; Create the topmost turtle.
;         set shape "circle"
;         set lastRing fput who lastRing
;         ]
;  read_ConfigFile         ; to get specifications: radius, # of teams & # of subteams.
;  build_Organization      ; by stepping trhough specs and creating teams and links
;
  generate_Random_Reliabilities
  rollUp_Reliabilities

end
;-----------------------------------------------------------
to makeRing_2 [radius numOrgs numSubs thisTier]

  let slice 0
  let wedgeSize 360 / numOrgs
  let orgNum 0
  let parent last lastRing             ; Get the first parent.
  set lastRing remove parent lastRing  ; Remove the parent from the list.
  let j 1                         ; Initialize the subteam counter.

  while [orgNum < numOrgs]
    [ crt 1                       ; create a turtle
      [
        set orgID who
        set shape "circle" set color blue
        set xcor radius * cos slice  ; calculate x
        set ycor radius * sin slice  ; calculate y
        set slice slice + wedgeSize  ; increment pie slice
        set label who                ; identify turtle
        set weight 0                 ; zero out the weight
        set tier thisTier            ; level within the organization
        set orgNum orgNum + 1        ; increment counter
        set currentRing fput who currentRing    ; populate the current ring
        set parentOrg parent
        create-link-to turtle parent
      ]
      if j = numSubs [
         if not empty? lastRing [
            set parent last lastRing           ; Get the first parent.
            set lastRing remove parent lastRing  ; Remove the parent from the list.
          ]
          set j 0                           ; Reset the subteam counter.
      ] ; end if
      set j j + 1                           ; Start the next count.
    ] ; end while
    set lastRing currentRing
    set currentRing []
end
;-------------------------------------------------------------
to read_ConfigFile
  file-close-all                     ; Ensure that all files are closed.
  file-open "Configuration.txt"

  let config file-read-line
  let cfgData substring config 0 10  ; Get the first 10 characters.
  let lineLength length config       ; Get the length of the input data


  if cfgData = "structure:" [
     set cfgData substring config 11 lineLength     ; Get the list from the string.

     set orgStructure read-from-string cfgData      ; Populate the global list.
  ]
end
;---------------------------------------------------------------
to build_Organization
  let numTiers length orgStructure    ; Get number of rings from global orgStructure.
  let i 0                             ; Initialize the ring counter.
  set Total_teams 0

  while [numTiers > 0]
    [
      let orgSpec item i orgStructure  ; Get a sublist from the orgStructure.
      let thisTier item 0 orgSpec      ; Get the current tier number.
      let radius item 1 orgSpec        ; Get the radius for this tier.
      let numOrgs item 2 orgSpec       ; Number of organizations in this tier.
      let numSubs item 3 orgSpec       ; Number of teams in organizations at this tier.

      set Total_teams Total_teams + numOrgs
      makeRing_2 radius numOrgs numSubs thisTier ; define organizations and teams

    ;  set radius radius + 4            ; Increase the radius for the next ring.
      set numTiers numTiers - 1        ; Decrease the number of remaining tiers.
      set i i + 1                      ; Increment the orgStructure item counter.
    ]

end
;---------------------------------------------------------------
to generate_Random_Weights
  ; Note: Add input fields for maximum and minimum weights.
  set System_Weight 0
  foreach lastRing [ ?1 ->
    ask turtle ?1 [
    set weight random Max_PtWt          ; value from input field
    if weight = 0 [set weight Min_PtWt] ; value from input field
    set color yellow
    set System_Weight (System_Weight + weight)
    ]
  ]
end
;---------------------------------------------------------------
to generate_Random_Reliabilities
  set System_Reliability 0

  foreach lastRing [ ?1 ->
    ask turtle ?1 [
    set reliability random-float 0.9999
    if reliability < 0.85 [set reliability 0.998]                 ; create an input field for minimum reliability
    set color green
    set System_Reliability (1 - (1 - System_Reliability) * (1 - reliability))
    ]
  ]
end
;---------------------------------------------------------------
to accumulate_weights
  let currentWeight 0
  foreach lastRing [ ?1 ->
    ask turtle ?1 [
       set currentWeight weight
       ask my-out-links [
         ask other-end [
         set weight (weight + currentWeight)
         if Accretion = true [
            let growth (1 + (Accretion_Percentage * 0.01))
        ;    print (sentence "growth " growth " turtle " who)
            set weight weight * growth          ; Integration adds some weight
         ] ; end if
         set color yellow
       ]
     ] ; end ask my-links

     set currentRing fput parentOrg currentRing
     wait 0.01
     set color blue
   ] ; end ask turtle ?
 ] ; next lastRing item
    set currentRing remove-duplicates currentRing

    foreach currentRing [ ?1 ->
      ask turtle ?1 [
         set System_Weight (System_Weight + weight)
         set nextTier tier - 1
      ] ; end ask
    ]  ; next currentRing
 set lastRing currentRing
 set currentRing []
end
;---------------------------------------------------------------
to accumulate_reliability
;
  let currentReliability 0

  foreach lastRing [ ?1 ->
    ask turtle ?1 [
       set currentReliability reliability
       ask my-out-links [
         ask other-end [
         set reliability (1 - (1 - reliability) * (1 - currentReliability))
         if Accretion = true [
           set reliability (reliability - 0.0001)      ; Integration decreases reliability
         ] ; end if
         set color green
           ;   print (sentence "turtle " who " ought to be green ")
       ]
     ] ; end ask my-links

     set currentRing fput parentOrg currentRing
     wait 0.01
     set color blue
   ] ; end ask turtle ?
 ] ; next lastRing item
    set currentRing remove-duplicates currentRing

    foreach currentRing [ ?1 ->
      ask turtle ?1 [

         set System_Reliability (1 - (1 - System_Reliability) * (1 - reliability))
         set nextTier tier - 1
      ] ; end ask
    ]  ; next currentRing
 set lastRing currentRing
 set currentRing []
end
;---------------------------------------------------------------
to rollUp_Weights
  let i 1
  let status "Roll up weights"
  while [i < 6] [
    print status
    set System_Weight 0
    accumulate_weights      ; lastRing ought to be the next ring inward
    set status (sentence "Current System Weight " System_Weight " Reset system weight for tier" nextTier)
    set i i + 1
  ]
end
;---------------------------------------------------------------
to rollUp_Reliabilities
  let i 1
  set System_Reliability 0
  let status "Roll up Reliabilities"
  while [i < 6] [
    print status
    accumulate_reliability     ; lastRing ought to be the next ring inward
    set status (sentence "Current System Reliability " System_Reliability " Reset system reliability for tier" nextTier)
    set i i + 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
187
10
810
634
-1
-1
13.68
1
10
1
1
1
0
1
1
1
-22
22
-22
22
0
0
1
ticks
30.0

BUTTON
100
63
163
96
NIL
Start
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
9
60
92
105
Total Weight
System_Weight
2
1
11

SWITCH
81
121
175
154
Accretion
Accretion
0
1
-1000

TEXTBOX
10
120
90
150
Integration adds weight?
11
0.0
1

TEXTBOX
8
10
176
55
Organizational Network\nWeight Accumulation
16
114.0
1

INPUTBOX
105
228
170
288
Max_PtWt
15.0
1
0
Number

INPUTBOX
16
228
80
288
Min_PtWt
1.0
1
0
Number

SLIDER
11
166
183
199
Accretion_Percentage
Accretion_Percentage
1
50
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
9
209
180
227
Minimum and Maximum Part Weights
10
51.0
1

MONITOR
97
364
178
409
NIL
Total_teams
0
1
11

MONITOR
68
305
180
350
NIL
System_Reliability
5
1
11

@#$#@#$#@
## WHAT IS IT?

A model of an organization with ideal communications where the outer-most ring
represents the lowest level tier of the organization and the center spot is the top of the organization. 

## HOW IT WORKS

Random weights are generated at the lowest tier and an accumulation function moves the
weight values to the integrating level in the next tier. Value changes are indicated by
changing colors. If the Accretion switch is on then each integrating level adds more
weight.

## HOW TO USE IT

Set the maximum and minimum weights for the random number generation and use the slider
to indicate the additional percentage of weight accumulated during integration. Press
the Start button to initiate the process of weight generation and accumulation.

## THINGS TO NOTICE

Notice that when the Accretion switch is off, the total weight does not change. The
reason is that the weights are simply handed up to the next level. When the accretion
switch is on then each tier adds integration weight based on a percentage of the weight
handed up from the lower tier.

## THINGS TO TRY

Try different accretion percentages and maximum and minimum part weights. Also, you can
change the number of organizations and teams at each level by editing the Configuration.txt file.

## EXTENDING THE MODEL

Future versions of this model will break links to represent organizations with imperfect
communications. Also, there will be links among the siblings at each tier to enable the
flow of information for negotiations on weight and reliabilities.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

An image of the user interface for this model appeared in the article "Organizational Simulation for Model Baed Systems Engineering" https://www.sciencedirect.com/science/article/pii/S1877050913000355
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
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
