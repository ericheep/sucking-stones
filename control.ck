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
    s[i].setEasingIncrement(0.0005);
    k[i].setEasingIncrement(0.0005);
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

4 => int NUM_MICS;

HPF hp[NUM_MICS];
Decay dec[NUM_MICS];
PitchedNoise ptchNois[NUM_MICS];
RandomReverse rev[NUM_MICS];
BufferGrabber buf[NUM_MICS];
GrainStretch str[NUM_MICS];

// analyzing classes
PitchTrack ptchTrk;
Decibel decib[NUM_MICS];

Gain in[NUM_MICS];
Gain out[NUM_MICS];

for (0 => int i; i < NUM_MICS; i++) {
    dec[i].decays(16);
    dec[i].length(6::second);
    dec[i].feedback(0.5);
    dec[i].mix(1.0);

    ptchTrk.frame(64);
    ptchTrk.overlap(1);

    rev[i].listen(1);

    // inputs in
    adc.chan(i) => in[i];
    in[i].gain(1.0);

    // analyzing classes
    in[i] => decib[i];
    in[i] => ptchTrk => blackhole;

    // sound chain
    in[i] => rev[i] => dec[i] => str[i];
    in[i] => buf[i];

    rev[i] => out[i];
    dec[i] => out[i];
    str[i] => out[i];
    ptchNois[i] => out[i];
    buf[i] => out[i];

    out[i] => dac.chan(i);
}

// control audio -~-~-~-~-~-~-~

30 => int decibelThreshold;
4 => int minDecays;
16 => int maxDecays;

1.0/60.0 => float decibelNormalizer;
maxDecays - minDecays => int decayRange;

0 => int stretchLatch;
0 => int stretchVal;

0 => int chunkLatch;
0 => int chunkVal;

0 => int recChunkLatch;
0 => int recChunkVal;

fun void updateAudio() {
    for (0 => int i; i < NUM_MICS; i++) {
        // input gain controls
        s[i * 2].getScaledVal() => float gainKnob;
        in[i].gain(gainKnob);

        // reverse controls
        k[i * 2].getScaledVal() => float revKnob;
        rev[i].setInfluence(revKnob);
        rev[i].setReverseGain(revKnob);

        // decay controls
        k[i * 2 + 1].getScaledVal() => float decayGain;
        dec[i].gain(decayGain);
        // dec[i].decays((decKnob * decayRange + minDecays)$int);

        // audio processing update
        ptchNois[i].setFreq(ptchTrk.get());
        ptchNois[i].setInputGain(decib[i].decibel() * decibelNormalizer);

        // noise controls
        s[i * 2 + 1].getEasedScaledVal() => float pitchedGain;
        ptchNois[i].gain(pitchedGain);

        // add a button to turn on stretching
        if (stretchLatch == 0 && n.s[i * 2] == 0) {
            1 => stretchLatch;
            <<< "Stretching Chunks:", i, stretchVal,  n.s[i * 2], "" >>>;
            (stretchVal + 1) % 2 => stretchVal;
            str[i].stretch(stretchVal);
        }
        if (stretchLatch == 1 && n.s[i * 2] > 0) {
            0 => stretchLatch;
        }

        // add a button to playing chunks
        if (chunkLatch == 0 && n.m[i * 2] == 0) {
            <<< "Playing Chunks:", i, chunkVal, "" >>>;
            (chunkVal + 1) % 2 => chunkVal;
            buf[i].playRandomChunks(chunkVal);
            1 => chunkLatch;
        }
        if (chunkLatch == 1 && n.m[i * 2] > 0) {
            0 => chunkLatch;
        }

        // add a button to record chunks
        if (recChunkLatch == 0 && n.r[i * 2] == 0) {
            <<< "Recording Chunks:", i, recChunkVal, "" >>>;
            (recChunkVal + 1) % 2 => recChunkVal;
            1 => recChunkLatch;
        }
        if (recChunkLatch == 1 && n.r[i * 2] > 0) {
            0 => recChunkLatch;
        }

        if (chunkVal) {
            buf[i].triggerGrab();
        }
    }
}

while (true) {
    updateControl();
    updateAudio();

    //<<< "Gains:", s[0].getScaledVal(), "Random Reverse:", k[0].getScaledVal(), " | Pitched Noise:", s[1].getScaledVal(), "Decay:", k[1].getScaledVal() >>>;

    updateDur => now;
}
