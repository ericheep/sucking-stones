// Eric Heep
// March 13th, 2017
// control.ck

NanoKontrol2 n;

class Slider extends MIDIValue {

}

class Knob extends MIDIValue {

}

8 => int NUM_SLIDERS;
8 => int NUM_KNOBS;

// control -~-~-~-~-~-~-~

Slider s[NUM_SLIDERS];
Knob k[NUM_KNOBS];

for (0 => int i; i < NUM_SLIDERS; i++) {
    s[i].setEasingIncrement(0.00005);
    k[i].setEasingIncrement(0.00005);
}

1::ms => dur updateDur;

fun void updateControl() {
    for (0 => int i; i < NUM_SLIDERS; i++) {
         s[i].setMidiVal(n.slider[i]);
    }
    for (0 => int i; i < NUM_KNOBS; i++) {
         k[i].setMidiVal(n.knob[i]);
    }
}

// audio -~-~-~-~-~-~-~

1 => int NUM_MICS;

Decay dec[NUM_MICS];
PitchTrack ptrk[NUM_MICS];


Gain master => dac;

for (0 => int i; i < NUM_MICS; i++) {
    dec[i].decays(16);
    dec[i].length(8::second);
    dec[i].feedback(0.5);
    dec[i].mix(1.0);

    ptrik[i].frame(512);
    ptrik[i].overlap(4);

    adc.chan(i) => dec[i] => master;
}

// control audio -~-~-~-~-~-~-~

fun void updateAudio() {
    for (0 => int i; i < NUM_MICS; i++) {
        dec[i].gain(k[i * 2].getEasedScaledVal());
    }
}

master => dac;

while (true) {
    updateControl();
    updateAudio();

    updateDur => now;
}
