4 => int NUM_MICS;

Gain g[NUM_MICS];

for (int i; i < NUM_MICS; i++) {
    adc.chan(i) => g[i] => dac.chan(i);
}

while (true) {
    1::second => now;
}




