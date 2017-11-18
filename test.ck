CNoise nois;
nois.gain(0.02);


while (true) {
    for (int i; i < 2; i++) {
        nois => dac.chan(i);
        .25::second => now;
        nois =< dac.chan(i);
    }
}
