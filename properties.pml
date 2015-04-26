/* Property name and its content mapping table
   <Safety>
   p1 
     If the system is disabled, all system components should return to their OFF state
   p2 
     Always when a pedestrian light is on WALK, the opposite vehicle stoplight must be RED
   p3 
     Always when a pedestrian light is on WALK, all vehicle turn lights must be RED
     -> This property is always failed, may consider to refine property discription 
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

/* Safety */
// If the system is disabled, all system components should return to their OFF state
//ltl p1 {
  /* TODO */
//}
// Always when a pedestrian light is on WALK, the opposite vehicle stoplight must be RED
ltl p2 {
  ([]( pedestrianLight[0]==WALK -> vehicleLight[0]==RED )) &&
  ([]( pedestrianLight[1]==WALK -> vehicleLight[1]==RED ))
}

// Always when a pedestrian light is on WALK, all vehicle turn lights must be RED
/* Init bug? Spec need to be clarify */
ltl p3 {
  []( (pedestrianLight[0]==WALK || pedestrianLight[1]==WALK) -> 
      (turnLight[0]==RED  && turnLight[1]==RED) )
}

// Always a pedestrian light is switched to WALK after the opposite vehicular lights have been switched to RED
ltl p4 {
  ([]( (pedestrianLight[0]==DONT_WALK && (X(pedestrianLight[0])==WALK)) -> 
        vehicleLight[0]==RED )) && 
  ([]( (pedestrianLight[1]==DONT_WALK && (X(pedestrianLight[1])==WALK)) -> 
        vehicleLight[1]==RED ))
}

// Always a pedestrian light is switched to DON’T WALK before the opposite vehicular lights are switched to GREEN
ltl p5 {
  ([]( (vehicleLight[0]==RED && (X(vehicleLight[0])==GREEN)) -> (pedestrianLight[0]==DONT_WALK) )) &&
  ([]( (vehicleLight[1]==RED && (X(vehicleLight[1])==GREEN)) -> (pedestrianLight[1]==DONT_WALK) ))
}

/* Liveness */
// Always, eventually: incoming pedestrians from any direction can cross the intersection in that direction.
ltl p6 {
  [](<>(pedestrianLight[0]==WALK) && <>(pedestrianLight[1]==WALK))
}

// Always, eventually: incoming vehicles from any direction can cross the intersection in that direction.
ltl p7 {
  [](<>(vehicleLight[0]==GREEN) &&
     <>(vehicleLight[1]==GREEN))
}

// Always, eventually: incoming vehicles from any direction can make a protected left turn.
ltl p8 {
  [](<>(turnLight[0]==GREEN) &&
     <>(turnLight[1]==GREEN))
}

// For any vehicle light (stoplight or turn light), always: the signal eventually turns ORANGE. 
ltl p9 {
  [](<>(vehicleLight[0]==ORANGE) &&
     <>(vehicleLight[1]==ORANGE) &&
     <>(turnLight[0]==ORANGE) &&
     <>(turnLight[1]==ORANGE))
}

// For any vehicle light (stoplight or turn light), always: if a GREEN signal is on, it stays on until the signal turns ORANGE.
ltl p10 {
  [](vehicleLight[0]==GREEN -> (vehicleLight[0]==GREEN U vehicleLight[0]==ORANGE)) &&
  [](vehicleLight[1]==GREEN -> (vehicleLight[1]==GREEN U vehicleLight[1]==ORANGE)) &&
  [](turnLight[0]==GREEN -> (turnLight[0]==GREEN U turnLight[0]==ORANGE)) &&
  [](turnLight[1]==GREEN -> (turnLight[1]==GREEN U turnLight[1]==ORANGE))
}

// For any vehicle light (stoplight or turn light), always: if a RED signal is on, it stays on until the signal turns GREEN.
ltl p11 {
  [](vehicleLight[0]==RED -> (vehicleLight[0]==RED U vehicleLight[0]==GREEN)) &&
  [](vehicleLight[1]==RED -> (vehicleLight[1]==RED U vehicleLight[1]==GREEN)) &&
  [](turnLight[0]==RED -> (turnLight[0]==RED U turnLight[0]==GREEN)) &&
  [](turnLight[1]==RED -> (turnLight[1]==RED U turnLight[1]==GREEN))
}