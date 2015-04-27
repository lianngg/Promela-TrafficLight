 /* Note, in this version, skip the following details:
   1. event queue capacity set to 1 (it's 5 in real code)
   2. don't have interrupt functionality for now.
      which means, can not disable when enable 
   3. do not handle error condition, if there's an error case, 
      SPIN will detect deadlock
   4. No delay now
   5. Do not implement block/unblock pedestrian control here
   
   // TODO, consider Delay?
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
bool pedestrianLightPositvieEdge[2] = false; // indicate from don't walk to walk 
bool pedestrianLightNegativeEdge[2] = false; // indicate from walk to don't walk
bool isIntersectionDisabled = false; // status of the intersection, true when it is disabled

/* Inline functions declaration */
// Make vehicle light RED, pedestrian light WALK and then notify the intersection
inline switchLinearToRed(id) {
  /* Odering bug in Java code here FIX !!*/
  vehicleLight[id]=RED; 
  if 
  :: pedestrianLight[id] == DONT_WALK -> pedestrianLightPositvieEdge[id] = true;
  :: else skip;
  fi
  pedestrianLight[id] = WALK;
  pedestrianLightPositvieEdge[id] = false;
  toIntersection!ACK;
}

// Refine from switchLinearToRed, if stopLight receive an INIT, it should
// call switchLinearToInit instead of switchLinearToRed
inline switchLinearToInit(id) {
  vehicleLight[id]=RED;
  pedestrianLight[id] = DONT_WALK;  // Fix here
  toIntersection!ACK;
}

// Make vehicle light GREEN or ORANGE, pedestrian light DONT_WALK
inline switchLinearTo(signal, id) {
  /* Odering bug in Java code here FIX */
  if 
  :: pedestrianLight[id] == WALK -> pedestrianLightNegativeEdge[id] = true;
  :: else skip;
  fi
  pedestrianLight[id]=DONT_WALK;
  pedestrianLightNegativeEdge[id] = false;
  vehicleLight[id]=signal; 
}

// Make vehicle light OFF, pedestrian light OFF
inline switchLinearToOff(id) {
  /* Odering bug in Java code here FIX */
  pedestrianLight[id]=OFF;
  vehicleLight[id]=OFF; 
}

// Make turn light RED and notify the intersection
inline switchTurnToRed(turn) {
  turn=RED;
  toIntersection!ACK;
}

// Make turn light GREEN or ORANGE
inline switchTurnTo(signal, turn) {
  turn=signal;
}

inline checkACKorInterupt() {
  do
  :: isIntersectionDisabled -> goto terminate; break;
  :: len(toIntersection) != 0 -> toIntersection?ACK; break;
  :: else skip;
  od
}

inline receiveEventOrInterupt(channel, event) {
  do
  :: isIntersectionDisabled -> goto terminate; 
  :: len(channel) != 0 -> channel?event; 
  :: else skip;
  od
}

/* Processes declaration */
proctype intersection() {
  run stopLightSet(0);
  run stopLightSet(1);
  run turnLightSet(0);
  run turnLightSet(1);

  // turn on stop lights
  toStopLightSet[0]!INIT;
  checkACKorInterupt();
  toStopLightSet[1]!INIT;
  checkACKorInterupt();
  // turn on turn lights
  toTurnLightSet[0]!INIT;
  checkACKorInterupt();
  toTurnLightSet[1]!INIT;
  checkACKorInterupt();
  
  toIntersection!ACK;  // Send an ACK to itself before entering the loop
  again:
    // advance stop lights
    checkACKorInterupt() -> toStopLightSet[0]!ADVANCE;
    checkACKorInterupt() -> toStopLightSet[1]!ADVANCE;
    
    // block pedestrians, notice that we only change the light status 
    // rather than model the detail operation of pedestrianLight on/off
    // because we think it's not important
    checkACKorInterupt() ->
    pedestrianLight[0] = DONT_WALK;
    pedestrianLight[1] = DONT_WALK;
    toIntersection!ACK; // send an ack to itself to let intersection move forward
    
    // advance turn lights
    checkACKorInterupt() -> toTurnLightSet[0]!ADVANCE;
    checkACKorInterupt() -> toTurnLightSet[1]!ADVANCE;
    
    // unblock pedestrians (No need to model this)
    
  goto again  // repeat again and again

  terminate:  // go to here only when the intersection is disabled
  end:
}

proctype stopLightSet(bit id) {
  receiveEventOrInterupt(toStopLightSet[id], INIT);
  switchLinearToInit(id);  // fix here
  do
  :: vehicleLight[id]==RED; 
     receiveEventOrInterupt(toStopLightSet[id], ADVANCE);
     switchLinearTo(GREEN, id);
     toStopLightSet[id]!PRE_STOP;
  :: vehicleLight[id]==GREEN; 
     receiveEventOrInterupt(toStopLightSet[id], PRE_STOP);
     switchLinearTo(ORANGE, id);
     toStopLightSet[id]!STOP;
  :: vehicleLight[id]==ORANGE; 
     receiveEventOrInterupt(toStopLightSet[id], STOP);
     switchLinearToRed(id);
  :: vehicleLight[id]==OFF;
     break;
  od

  terminate:
  end: pedestrianLight[id] = OFF; vehicleLight[id] = OFF;
}

proctype turnLightSet(bit id) {
  receiveEventOrInterupt(toTurnLightSet[id], INIT);
  switchTurnToRed(turnLight[id]);
  do
  :: turnLight[id]==RED; 
     receiveEventOrInterupt(toTurnLightSet[id], ADVANCE);
     switchTurnTo(GREEN, turnLight[id]);
     toTurnLightSet[id]!PRE_STOP;
  :: turnLight[id]==GREEN; 
     receiveEventOrInterupt(toTurnLightSet[id], PRE_STOP);
     switchTurnTo(ORANGE, turnLight[id]);
     toTurnLightSet[id]!STOP;
  :: turnLight[id]==ORANGE; 
     receiveEventOrInterupt(toTurnLightSet[id], STOP);
     switchTurnToRed(turnLight[id]);
  :: turnLight[id]==OFF;
     break;
  od

  terminate:
  end: turnLight[id] = OFF;
}

proctype disable() {
/* Index bug of the loop in Java code here FIX */
  atomic {  // Interrupt the intersection
    empty(toIntersection);
    isIntersectionDisabled = true;
  }
  
  // Clear toStopLightSet[0]
  pedestrianLight[0] = OFF;
  vehicleLight[0] = OFF;
  
  // Clear toStopLightSet[1]
  pedestrianLight[1] == OFF;
  vehicleLight[1] = OFF;
   
  // Clear toTurnLightSet[0]
  turnLight[0] = OFF;
  
  // Clear toTurnLightSet[1]
  turnLight[1] = OFF;
}

init {
  run intersection();
  run disable();
}
