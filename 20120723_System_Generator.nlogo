globals [System]
turtles-own [priority name H L W volume weight]

to Setup
  clear-all
  readConfiguration
  generateNetwork
  negotiateDimensions
  calculateVolumeWeight
end
;-----------------------------------------
to readConfiguration
  file-close-all
  file-open "Generated_System.txt"
  set System []         ; establish lists
  let subsystem[]

  while [not file-at-end?] [
   let config file-read-line
   set subsystem read-from-string config
  ; show subsystem
   set System fput subsystem System
  ]
  file-close
end
;------------------------------------------
to generateNetwork
  let iNodes length System
  let i 0          ; turtle counter
  crt iNodes [
    set shape "circle"
    set color cyan
    set size 10
    set L 0.101         ; part length
    set H 0.101         ; part height
    set W 0.101         ; part width
   ;; set label (sentence "#" who " L:" L " H:" H " W:" W)
    set label who
  ]

  foreach System [ ?1 ->
    let subsystem ?1
    let numLinks length subsystem
    set i (item 0 subsystem - 1)
    ask turtle i [
        set priority item 0 subsystem
        set name item 1 subsystem
        let j 2                       ; Initialize link item number.
        set iNodes length subsystem   ; Reset number of nodes to number of items in list.
        while [j < iNodes] [
          let k item j subsystem      ; Get the number for this item.
          set k k - 1                 ; Subtract one because turtle numbering starts at zero.
          if who != k [               ; Ensure that the turtle does not try to link with itself.
             create-link-with turtle k   ; Establish link with that turtle.
          ]
          set j j + 1                 ; Set the item counter to the next item number.
        ]  ; end while
    ] ; end ask
  ] ; next subsystem

   layout-circle turtles 250

  ; repeat 30 [ layout-spring turtles links 0.2 150 30 ]

end
;--------------------------------------------------------
to negotiateDimensions
  let us WeChange                    ; break-point for this team to change its part dimensions
  let them TheyChange                ; break-point for the othe team changing their dimensions
  let neither NeitherChange          ; break-point for neither team changing dimensions
  let tnum 999                       ; current other team number
  let c 0                            ; current link color variable
  let cotp -1                        ; current other team's priority - used to decide dimension change
  let conp -1                        ; next current other team's priority - used for comparison
  let tH 0 let tL 0 let tW 0         ; dimensions of part from the current other team

  ask turtles [                                      ; Step through each team.
    let otherTeams sort my-links                     ; Create a list of the links with the current team.
    let fot first otherTeams                         ; Get the link to the first of other teams.
    ask fot [ask other-end [ set cotp priority] ]    ; Get the first other-team's priority.
    foreach otherTeams [ ?1 ->                             ; Step through each of the links with the other teams.
       ask ?1 [ask other-end [set conp priority] ]    ; Get the current other team's priority for comparison.
       ask ?1 [set c color ]                          ; Store the current color of of the current link.
       ask ?1 [ask other-end [set color red]]
       ask turtle who [ set color blue]
      ; Set check sign to random integers from zero or one.
       let cs1 random 1 let cs2 random 1 let cs3 random 1
      ; Set deltas dimensions to random floating numbers ranging from zero to two.
       let dL random-float 0.04 let dH random-float 0.04 let dW random-float 0.04
     ; If the check signs are one then multiply the delta dimensions by negative one.
     if cs1 = 1 [set dL dL * -1]  if cs2 = 1 [set dH dH * -1]  if cs3 = 1 [set dW dW * -1]

       let interaction random 100    ; Generate an interaction value from zero to 100.
 ; if the interaction value is greater than 70 then both teams will change their part dimensions.
 ; Compare interaction values to the numbers that determine whether we they both or neither change.
       if interaction >= neither and interaction <= them [   ; they change
          ask ?1 [ ask other-end [ if L + dL > 0 [set L L + dL]
                                  if H + dH > 0 [set H H + dH]
                                  if W + dW > 0 [set W W + dW] set tnum who
                                  set tL L set tH H set tW W]
                                  set color red ]
        ] ; end if
        if interaction >= them and interaction <= us [       ; we change
          if conp >= cotp [                          ; Compare other team's priority to last priority.
          ask turtle who [if L + dL > 0 [set L L + dL]
                          if H + dH > 0 [set H H + dH]
                          if W + dW > 0 [set W W + dW] ]  ; Modify the dimensions by the delta values.
          ask ?1 [set color blue]
          ]
        ] ; end if
        if interaction > us [
           ask ?1 [ask other-end [ if L + dL > 0 [set L L + dL]
                                  if H + dH > 0 [set H H + dH]
                                  if W + dW > 0 [set W W + dW] set tnum who] ] ; both change
           if conp >= cotp [                          ; Compare other team's priority to last priority.
           ask turtle who [if L + dL > 0 [set L L + dL]
                          if H + dH > 0 [set H H + dH]
                          if W + dW > 0 [set W W + dW] ]
           ]
           ask ?1 [set color yellow]
        ] ; end if

  ;     show (sentence "team" who "L:" L "H:" H "W:" W " other team" tnum "L:"tL  "H:"tH  "W:"tW  )
       wait 0.1
       ask ?1 [set color c ask other-end [set color cyan]]    ; pause resetting colors.
              ask turtle who [set color cyan]
       set cotp conp
     ] ; next of my-links
  ] ; end ask
end
;----------------------------------------------------------------------------------
to calculateVolumeWeight
  ; set subsystemWeights []
   ; http://www.engineeringtoolbox.com/metal-alloys-densities-d_50.html
   let density 8497           ; Density of Inconel in kilograms per cubic meter
   let unitConversion 0.1     ; Reduce dimensions from meters to tenths of meters
   let pL 0 let pH 0 let pW 0 ; Variables for holding the converted dimensions
   let thick 0.001

   file-close-all
   file-open "Generated_Weights.txt"

   ask turtles [
      set pL L * unitConversion
      set pH H * unitConversion
      set pW W * unitConversion
      ; Build a hollow box.
      set volume (2 * (pL * pW * thick) + 2 * (pL * pH * thick) + 2 * (pW * pH * thick))
      set weight volume * density
      file-print weight
      show weight
   ]
   file-flush
   file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
819
620
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-300
300
-300
300
0
0
1
ticks
30.0

BUTTON
101
83
165
116
NIL
Setup
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
16
244
192
308
This simulation completes in approximately three minutes for 108 interacting teams.
14
0.0
1

TEXTBOX
19
313
194
418
Blue circles indicate the current team that is negotiating with other team. Blue lines indicate that the current team is changing dimensions of its part.
14
104.0
1

TEXTBOX
20
422
205
541
Red circles indicate the other teams that are negotiating with the current team. Red lines indicate that the other team is changing the dimension of its part.
14
12.0
1

TEXTBOX
20
550
201
720
Yellow lines indicate that the current team and the other team are both changing the dimensions of their parts.\n\nNo line indicates that neither team is changing part dimensions.
14
0.0
1

TEXTBOX
225
657
792
708
The Command Center shows the results of the interactions. Numbers at the end represent the weights of the boxes. Volume calculations assume hollow boxes with 0.001m thick walls. Density is based on Inconel at 8497kg/m^3.
12
0.0
1

INPUTBOX
10
10
94
70
NeitherChange
20.0
1
0
Number

INPUTBOX
100
11
166
71
WeChange
80.0
1
0
Number

INPUTBOX
12
76
90
136
TheyChange
60.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

A ring of turtles represent interacting teams. Lines between between the turtles represent interactions. During the simulations, communication lines are highlighted as teams interact. Ultimately, the teams negotiate and compromise on design requirements, which affect the weight of their subsystems. At the end of the simulation, a list of numbers appears in the Command Center; those values represent the weights in kilograms of each team's subsystem.

## HOW IT WORKS

The code reads a file named Generated_System.txt; that file identifies the teams and the connections to other teams. The Generated_System.txt file was produced from an Excel workbook, named 20120723_System_DSM_Generator.xlsm, with Visual Basic for Applications (VBA) macros.

## HOW TO USE IT

Press the Setup button. Three fields on the user interface identify the likelihood that a team compromises during a negotiation. The Neither Change value indicates a percentage wherein both teams won't change their position in a negotion. The We Change value indicates a likelihood percentage that the currently active team will accept changes required by the other team. The They Change field value indicates the likelihood that the other team will accept changes from the currently active team.

## THINGS TO NOTICE

At the end of the simulation, a list of weights, in kilograms, appears in the Command Center. Visually, notice the lines that change color during the simulation; those lines indicate the current negotiation between two teams.

## THINGS TO TRY

Try changing the values in the input fields the numbers should be greater than zero and less than 100.

## EXTENDING THE MODEL

Ideas of extending the model include a planned or allocated weight for each team and the actual weight at the end of the simulation. A final report could indicate the planned, actual, and differences in the weights.

## NETLOGO FEATURES

This code was developed with version 5.0.1, it has been tested with version 6.2.2.

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

An image of this model's user interface appeared in the article "Organizational Simulation for Model Based Systems Engineering" https://www.sciencedirect.com/science/article/pii/S1877050913000355
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
