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
PitchedNoise ptchNois[NUM_MICS];

// analyzing classes
PitchTrack ptchTrk[NUM_MICS];
Decibel decib[NUM_MICS];


Gain master => dac;

for (0 => int i; i < NUM_MICS; i++) {
    dec[i].decays(16);
    dec[i].length(8::second);
    dec[i].feedback(0.5);
    dec[i].mix(1.0);

    ptchTrk[i].frame(64);
    ptchTrk[i].overlap(1);

    adc.chan(i) => dec[i] => master;
    ptchNois[i] => master;
    adc.chan(i) => ptchTrk[i] => blackhole;
    adc.chan(i) => decib[i];
}

// control audio -~-~-~-~-~-~-~

fun void updateAudio() {
    for (0 => int i; i < NUM_MICS; i++) {
        // audio processing update
        ptchNois[i].setFreq(ptchTrk[i].get());
        ptchNois[i].setInputGain(decib[i].decibel()/60.0);


        // gain control update
        dec[i].gain(k[i * 2].getEasedScaledVal());
        ptchNois[i].gain(k[i * 2 + 1].getScaledVal());
    }
}

master => dac;

while (true) {
    updateControl();
    updateAudio();

    <<< decib[0].decibel(), ptchTrk[0].get(), k[1].getEasedScaledVal() >>>;

    updateDur => now;
}
