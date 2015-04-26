 /* Note, in this version, skip the following details:
   1. event queue capacity set to 1 (it's 5 in real code)
   2. don't have interrupt functionality for now.
      which means, can not disalbe when enable 
   3. do not handle error condition, if there's an error case, 
      SPIN will detect deadlock
   4. No delay now
   5. Do not implement block/unblock pedestrian control here
   
   // TODO, consider Delay?
   // TODO, refactor code to make it more readlbe 
 */ 

#include "properties.pml"

mtype = {OFF, GREEN, RED, ORANGE};  // signal state of vehicle and turn light
mtype = {WALK, DONT_WALK};          // signal state of pedestrian light
mtype = {INIT, ADVANCE, PRE_STOP, STOP, ALL_STOP};  // events
mtype = {ACK};   // whenever light-set finished its task, send ACK to toIntersection 
                 // channel to let intersection move forward

/* Channels declaration */
chan toStopLightSet[2] = [1] of {mtype}; // event queue for StopLights
chan toTurnLightSet[2] = [1] of {mtype}; // event queue for TurnLights
chan toIntersection = [1] of {mtype};    // let light-sets to notfiy intersection

/* Global variables to reflect current status */
mtype vehicleLight[2] = OFF;      // status of vehicleLight, can be OFF, GREEN, RED, ORANGE
mtype pedestrianLight[2] = OFF;   // status of pedestrianLight, can be OFF, WALK, DONT_WALK
mtype turnLight[2] = OFF;         // status of turnLight, can be OFF, GREEN, RED, ORANGE

/* Inline functions declaration */
// Make vehicle light RED, pedestrian light WALK and then notify the intersection
inline switchLinearToRed(vehicle, pedestrian) {
  /* Odering bug in Java code here */
  vehicle=RED;
  pedestrian = WALK;
  toIntersection!ACK;
}

// Refine from switchLinearToRed, if stopLight receive an INIT, it should
// call switchLinearToInit instead of switchLinearToRed
inline switchLinearToInit(vehicle, pedestrian) {
  vehicle=RED;
  pedestrian = DONT_WALK;  // Fix here
  toIntersection!ACK;
}

// Make vehicle light GREEN or ORANGE, pedestrian light DONT_WALK
inline switchLinearTo(signal, vehicle, pedestrian) {
  /* Odering bug in Java code here */
  pedestrian=DONT_WALK;
  vehicle[id]=signal; 
}

// Make turn light RED and notify the intersection
inline switchTurnToRed(turn) {
  turn=RED;
  toIntersection!ACK;
}

// Make turn light GREEN or ORANGE and notify the intersection
inline switchTurnTo(signal, turn) {
  turn=signal;
}

/* Processes declaration */
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
    
    // block pedestrians, please we only change the light status 
    // but not model the detail operation of pedestrianLight on/off because
    // we think it's not important
    toIntersection?ACK ->
    pedestrianLight[0] = DONT_WALK;
    pedestrianLight[1] = DONT_WALK;
    toIntersection!ACK; // send an ack to itself to let intersection move forward
    
    // advance turn lights
    toIntersection?ACK -> toTurnLightSet[0]!ADVANCE;
    toIntersection?ACK -> toTurnLightSet[1]!ADVANCE;
    
    // unblock pedestrians (No need to model this)
    
  goto again  // repeat again and again
}

proctype stopLightSet(bit id) {
  toStopLightSet[id]?INIT -> 
  switchLinearToInit(vehicleLight[id], pedestrianLight[id]);  // fix here
  do
  :: vehicleLight[id]==RED; 
     toStopLightSet[id]?ADVANCE -> 
     switchLinearTo(GREEN, vehicleLight[id], pedestrianLight[id]);
     toStopLightSet[id]!PRE_STOP;
  :: vehicleLight[id]==GREEN; 
     toStopLightSet[id]?PRE_STOP -> 
     switchLinearTo(ORANGE, vehicleLight[id], pedestrianLight[id]);
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
     switchTurnTo(GREEN, turnLight[id]);
     toTurnLightSet[id]!PRE_STOP;
  :: turnLight[id]==GREEN; 
     toTurnLightSet[id]?PRE_STOP -> 
     switchTurnTo(ORANGE, turnLight[id]);
     toTurnLightSet[id]!STOP;
  :: turnLight[id]==ORANGE; 
     toTurnLightSet[id]?STOP ->
     switchTurnToRed(turnLight[id]);
  od
}

init {
  run intersection();
}
