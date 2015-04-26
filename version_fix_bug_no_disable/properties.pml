/* Property name and its content mapping table
   <Safety>
   p1 
     If the system is disabled, all system components should return to their OFF state
   p2 
     Always when a pedestrian light is on WALK, the opposite vehicle stoplight must be RED
   p3 
     Always when a pedestrian light is on WALK, all vehicle turn lights must be RED
   p4
     Always a pedestrian light is switched to WALK after the opposite vehicular lights
     have been switched to RED
   p5 
     Always a pedestrian light is switched to DON’T WALK before the opposite vehicular
     lights are switched to GREEN
     
   <Liveness>  
   p6 
     Always, eventually: incoming pedestrians from any direction can cross the
     intersection in that direction.  
   p7 
     Always, eventually: incoming vehicles from any direction can cross the 
     intersection in that direction
   p8 
     Always, eventually: incoming vehicles from any direction can make a protected left turn
   p9
     For any vehicle light (stoplight or turn light), always: the signal eventually turns ORANGE
   p10
     For any vehicle light (stoplight or turn light), always: if a GREEN signal is on, it stays
     on until the signal turns ORANGE
   p11
     For any vehicle light (stoplight or turn light), always: if a RED signal is on, it stays on
     until the signal turns GREEN           
*/

#define pedestrianWalkImplyVehicleLightRed(i) ([]( pedestrianLight[i]==WALK -> vehicleLight[i]==RED  ))
#define vehicleLightGreen(i) ( vehicleLight[i]==GREEN )
#define vehicleLightOrange(i) ( vehicleLight[i]==ORANGE )
#define vehicleLightRed(i) ( vehicleLight[i]==RED )
#define turnLightGreen(i) ( turnLight[i]==GREEN )
#define turnLightOrange(i) ( turnLight[i]==ORANGE )
#define turnLightRed(i) ( turnLight[i]==RED )
#define pedestrianLightWalk(i) (pedestrianLight[i] == WALK)
#define pedestrianLightDontWalk(i) (pedestrianLight[i] == DONT_WALK)

/* Safety */
// p0: Once enabled, the system should not deadlock until it is interrupted or disabled.
// This property will be checked by SPIN Safety option

// If the system is disabled, all system components should return to their OFF state
//ltl p1 {
  /* TODO */
//}

// Always when a pedestrian light is on WALK, the opposite vehicle stoplight must be RED   
ltl p2 {
  pedestrianWalkImplyVehicleLightRed(0) &&
  pedestrianWalkImplyVehicleLightRed(1)
}

// Always when a pedestrian light is on WALK, all vehicle turn lights must be RED
/* Init bug? Spec need to be clarify */
ltl p3 {
  []( (pedestrianLightWalk(0) || pedestrianLightWalk(1) ) -> 
      (turnLightRed(0)  && turnLightRed(1) ))
}

// Always a pedestrian light is switched to WALK after the opposite vehicular lights have been switched to RED

ltl p4 {
  ([]( (pedestrianLight[0]==DONT_WALK && (X(pedestrianLight[0])==WALK)) -> vehicleLight[0]==RED )) && 
  ([]( (pedestrianLight[1]==DONT_WALK && (X(pedestrianLight[1])==WALK)) -> vehicleLight[1]==RED ))
}


// Always a pedestrian light is switched to DON’T WALK before the opposite vehicular lights are switched to GREEN
ltl p5 {
  ([]( (vehicleLight[0]==RED && (X(vehicleLight[0])==GREEN)) -> (pedestrianLight[0]==DONT_WALK) )) &&
  ([]( (vehicleLight[1]==RED && (X(vehicleLight[1])==GREEN)) -> (pedestrianLight[1]==DONT_WALK) ))
}

/* Liveness */
// Always, eventually: incoming pedestrians from any direction can cross the intersection in that direction.
ltl p6 {
  []((<>pedestrianLightWalk(0)) && (<>pedestrianLightWalk(1)))
}

// Always, eventually: incoming vehicles from any direction can cross the intersection in that direction.
ltl p7 {
  []( (<>vehicleLightGreen(0)) && (<>vehicleLightGreen(1)) )
}

// Always, eventually: incoming vehicles from any direction can make a protected left turn.
ltl p8 {
  []( (<>turnLightGreen(0)) && (<>turnLightGreen(1)) )
}

// For any vehicle light (stoplight or turn light), always: the signal eventually turns ORANGE. 
ltl p9 {
  []((<>turnLightOrange(0)) &&
     (<>turnLightOrange(1)) &&
     (<>vehicleLightOrange(0)) &&
     (<>vehicleLightOrange(1)))
}

// For any vehicle light (stoplight or turn light), always: if a GREEN signal is on, it stays on until the signal turns ORANGE.
ltl p10 {
  [](vehicleLightGreen(0) -> (vehicleLightGreen(0) U vehicleLightOrange(0))) &&
  [](vehicleLightGreen(1) -> (vehicleLightGreen(1) U vehicleLightOrange(1))) &&
  [](turnLightGreen(0) -> (turnLightGreen(0) U turnLightOrange(0))) &&
  [](turnLightGreen(0) -> (turnLightGreen(0) U turnLightOrange(0)))
}

// For any vehicle light (stoplight or turn light), always: if a RED signal is on, it stays on until the signal turns GREEN.
ltl p11 {
  [](vehicleLightRed(0) -> (vehicleLightRed(0) U vehicleLightGreen(0))) &&
  [](vehicleLightRed(1) -> (vehicleLightRed(1) U vehicleLightGreen(1))) &&
  [](turnLightRed(0) -> (turnLightRed(0) U turnLightGreen(0))) &&
  [](turnLightRed(1) -> (turnLightRed(1) U turnLightGreen(1)))
}
