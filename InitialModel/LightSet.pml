#define switchTo(a) {state[id] = a; signal[0] = a; signal[1] = a;}

mtype = {INIT, ADVANCE, PRE_STOP, STOP, ALL_STOP, NOTIFY} /* Message types */
mtype = {OFF, RED, GREEN, ORANGE} /* Signal status */

chan eventQueue[4] = [100] of {mtype}

mtype state[4];

proctype LightSet(int id) {
    state[id] = OFF;
    mtype signal[2];
    signal[0] = OFF;
    signal[1] = OFF;

    do
    :: eventQueue[id] ? INIT -> {
            switchTo(RED);
        }
    :: eventQueue[id] ? ADVANCE -> {
        switchTo(GREEN);
        eventQueue[id] ! PRE_STOP;
    }
    :: eventQueue[id] ? PRE_STOP -> {
        switchTo(ORANGE);
        eventQueue[id] ! STOP;
    }
    :: eventQueue[id] ? STOP -> {
        switchTo(RED);
        eventQueue[id] ! NOTIFY;
    }
    od
}
