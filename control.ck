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
RandomReverse rev[NUM_MICS];
BufferGrabber buf[NUM_MICS];

Gain master => dac;

for (0 => int i; i < NUM_MICS; i++) {
    dec[i].decays(16);
    dec[i].length(8::second);
    dec[i].feedback(0.5);
    dec[i].mix(1.0);

    ptchTrk[i].frame(64);
    ptchTrk[i].overlap(1);

    rev[i].listen(1);

    adc.chan(i) => ptchTrk[i] => blackhole;

    adc.chan(i) => buf[i] => rev[i];
    adc.chan(i) => dec[i] => rev[i];
    adc.chan(i) => decib[i];

    rev[i] => ptchNoise[i];
    rev[i] => master;
    ptchNois[i] => master;
}

// control audio -~-~-~-~-~-~-~

30 => int decibelThreshold;
4 => int minDecays;
32 => int maxDecays;

1.0/60.0 => float decibelNormalizer;
maxDecays - minDecays => int decayRange;

fun void updateAudio() {
    for (0 => int i; i < NUM_MICS; i++) {
        // audio processing update
        ptchNois[i].setFreq(ptchTrk[i].get());
        ptchNois[i].setInputGain(decib[i].decibel() * decibelNormalizer);

        // decay controls
        k[i * 2].getEasedScaledVal() => float decKnob;
        dec[i].gain(decKnob);
        dec[i].((decKnob * decayRange + minDecays)$int);

        // reverse controls
        k[i * 2 + 1].getEasedScaledVal() => float revKnob;
        rev[i].setInfluence(revKnob);
        rev[i].setReverseGain(revKnob);

        // noise controls
        ptchNois[i].gain(s[i * 2 + 1].getEasedScaledVal());

        // buffer control
        if (decib[i].decibel() > decibelThreshold) {
            buf[i].triggerGrab();
        }
    }
}

master => dac;

while (true) {
    updateControl();
    updateAudio();

    <<< decib[0].decibel(), ptchTrk[0].get(), k[1].getEasedScaledVal() >>>;

    updateDur => now;
}
