mtype = {OFF, GREEN, RED, ORANGE};  // signal state of vehicle and turn light
mtype = {WALK, DONT_WALK};  // signal state of pedestrian light
mtype = {INIT, ADVANCE, PRE_STOP, STOP, ALL_STOP};  // events
mtype = {ACK};

chan toStopLightSet[2] = [1] of {mtype};
chan toTurnLightSet[2] = [1] of {mtype};
chan toIntersection = [1] of {mtype};

mtype vehicleLight[2] = OFF;
mtype pedestrianLight[2] = OFF;
mtype turnLight[2] = OFF;

proctype intersection() {
  // turn on stop lights
  toStopLightSet[0]!INIT;
  toIntersection?ACK;
  toStopLightSet[1]!INIT;
  toIntersection?ACK;
  // turn on turn lights
  toTurnLightSet[0]!INIT;
  toIntersection?ACK;
  toTurnLightSet[1]!INIT;
  toIntersection?ACK;
  
  toIntersection!ACK;  // Send an ACK to itself before entering the loop
  again:
    // advance stop lights
    toIntersection?ACK -> toStopLightSet[0]!ADVANCE;
    toIntersection?ACK -> toStopLightSet[1]!ADVANCE;
    
    // block pedestrians
    toIntersection?ACK ->
    pedestrianLight[0] = DONT_WALK;
    pedestrianLight[1] = DONT_WALK;
    toIntersection!ACK;
    
    // advance turn lights
    toIntersection?ACK -> toTurnLightSet[0]!ADVANCE;
    toIntersection?ACK -> toTurnLightSet[1]!ADVANCE;
    
    // unblock pedestrians (No need to model this)
    
  goto again
}

proctype stopLightSet(bit id) {
  toStopLightSet[id]?INIT -> 
  vehicleLight[id]=RED; pedestrianLight[id] = WALK;  /* Odering bug in Java code here */
  toIntersection!ACK;
  do
  :: vehicleLight[id]==RED; 
  	 toStopLightSet[id]?ADVANCE -> 
  	 pedestrianLight[id]=DONT_WALK; 
  	 vehicleLight[id]=GREEN; 
  	 toStopLightSet[id]!PRE_STOP;
  :: vehicleLight[id]==GREEN; 
     toStopLightSet[id]?PRE_STOP -> pedestrianLight[id]=DONT_WALK;
     vehicleLight[id]=ORANGE; 
     toStopLightSet[id]!STOP;
  :: vehicleLight[id]==ORANGE; 
     toStopLightSet[id]?STOP -> vehicleLight[id]=RED; 
     pedestrianLight[id] = WALK; 
     toIntersection!ACK;
  od
}

proctype turnLightSet(bit id) {
  toTurnLightSet[id]?INIT -> turnLight[id]=RED;
  toIntersection!ACK;
  do
  :: turnLight[id]==RED; 
     toTurnLightSet[id]?ADVANCE -> turnLight[id]=GREEN; 
     toTurnLightSet[id]!PRE_STOP;
  :: turnLight[id]==GREEN; 
     toTurnLightSet[id]?PRE_STOP -> turnLight[id]=ORANGE; 
     toTurnLightSet[id]!STOP;
  :: turnLight[id]==ORANGE; 
     toTurnLightSet[id]?STOP -> turnLight[id]=RED; 
     toIntersection!ACK;
  od
}

init {
  run stopLightSet(0);
  run stopLightSet(1);
  run turnLightSet(0);
  run turnLightSet(1);
  run intersection();
}

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
