#include "LightSet.pml"
#define readyLinear atomic {eventQueue[0] ? [NOTIFY] && eventQueue[1] ? [NOTIFY] -> eventQueue[0] ? NOTIFY; eventQueue[1] ? NOTIFY;}
#define readyTurn atomic {eventQueue[2] ? [NOTIFY] && eventQueue[3] ? [NOTIFY] -> eventQueue[2] ? NOTIFY; eventQueue[3] ? NOTIFY;}
#define linearInit {eventQueue[0] ! INIT; eventQueue[1] ! INIT;}
#define turnInit {eventQueue[2] ! INIT; eventQueue[3] ! INIT;}
#define advanceLinearLights {eventQueue[0] ! ADVANCE; eventQueue[1] ! ADVANCE;}
#define advanceTurnLights {eventQueue[2] ! ADVANCE; eventQueue[3] ! ADVANCE; }

mtype = {ENABLED, FAILED, DISABLED}  /* Intersection status */ 

ltl p {
    []<>(state[0] == GREEN) && []<>(state[1] == GREEN) && []<>(state[2] == GREEN) && []<>(state[3] == GREEN) &&
    []<>(state[0] == ORANGE) && []<>(state[1] == ORANGE) && []<>(state[2] == ORANGE) && []<>(state[3] == ORANGE) &&
    []<>(state[0] == RED) && []<>(state[1] == RED) && []<>(state[2] == RED) && []<>(state[3] == RED)
}

proctype Intersection() {
    mtype status = DISABLED;
    run LightSet(0);
    run LightSet(1);
    run LightSet(2);
    run LightSet(3);
    do
    :: status == DISABLED -> {
            /* Turns on the the linear light sets L0 and L1. */
            status = ENABLED; 
            linearInit;
            turnInit;
        }
    :: status == ENABLED -> {
        /* Advance the linear light sets L0 and L1 and let them go through their cycle. */
        advanceLinearLights;
        readyLinear;
        advanceTurnLights;
        readyTurn;
    }
    od
}

init {
    run Intersection();
}
