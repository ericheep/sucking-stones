4 => int NUM_MICS;

CNoise nois;

nois.gain(0.02);


while (true) {
    for (int i; i < 4; i++) {
        nois => dac.chan(i);
        .5::second => now;
        nois =< dac.chan(i);
    }
}
