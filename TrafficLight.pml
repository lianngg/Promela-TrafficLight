#include "properties.pml" 

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


// Make vehicle light RED, pedestrian light WALK and then notify the intersection
inline switchLinearToRed(vehicle, pedestrian) {
  /* Odering bug in Java code here */
  vehicle=RED;
  pedestrian = WALK;
  toIntersection!ACK;
}

// Make turn light RED and notify the intersection
inline switchTurnToRed(vehicle) {
  vehicle=RED;
  toIntersection!ACK;
}

proctype intersection() {
  run stopLightSet(0);
  run stopLightSet(1);
  run turnLightSet(0);
  run turnLightSet(1);

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
  switchLinearToRed(vehicleLight[id], pedestrianLight[id]);
  do
  :: vehicleLight[id]==RED; 
     toStopLightSet[id]?ADVANCE -> 
     pedestrianLight[id]=DONT_WALK; 
     vehicleLight[id]=GREEN; 
     toStopLightSet[id]!PRE_STOP;
  :: vehicleLight[id]==GREEN; 
     toStopLightSet[id]?PRE_STOP -> 
     pedestrianLight[id]=DONT_WALK;
     vehicleLight[id]=ORANGE; 
     toStopLightSet[id]!STOP;
  :: vehicleLight[id]==ORANGE; 
     toStopLightSet[id]?STOP ->
     switchLinearToRed(vehicleLight[id], pedestrianLight[id]);
  od
}

proctype turnLightSet(bit id) {
  toTurnLightSet[id]?INIT -> 
  switchTurnToRed(turnLight[id]);
  do
  :: turnLight[id]==RED; 
     toTurnLightSet[id]?ADVANCE -> 
     turnLight[id]=GREEN; 
     toTurnLightSet[id]!PRE_STOP;
  :: turnLight[id]==GREEN; 
     toTurnLightSet[id]?PRE_STOP -> 
     turnLight[id]=ORANGE; 
     toTurnLightSet[id]!STOP;
  :: turnLight[id]==ORANGE; 
     toTurnLightSet[id]?STOP ->
     switchTurnToRed(turnLight[id]);
  od
}

init {
  run intersection();
}

