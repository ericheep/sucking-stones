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

2 => int NUM_MICS;

HPF hp[NUM_MICS];
Decay dec[NUM_MICS];
RandomReverse rev[NUM_MICS];
GrainStretch str[NUM_MICS];
AsymptopicChopper asy[NUM_MICS];
LoopingChopper chp[NUM_MICS];

Gain in[NUM_MICS];
ADSR panEnv[NUM_MICS];
Gain out[NUM_MICS];

10::ms => dur panEnvDuration;

for (0 => int i; i < NUM_MICS; i++) {
    dec[i].decays(16);
    dec[i].length(6::second);
    dec[i].feedback(0.5);
    dec[i].mix(1.0);
    dec[i].decayGain(0.0);

    rev[i].listen(1);
    asy[i].listen(1);
    chp[i].listen(1);

    str[i].gain(1.0);

    // inputs in
    adc.chan(i) => in[i];

    // sound chain
    in[i] => rev[i] => dec[i];
    dec[i] => asy[i];
    dec[i] => str[i];
    dec[i] => chp[i];

    dec[i] => out[i];
    asy[i] => out[i];
    chp[i] => out[i];
    rev[i] => out[i];
    str[i] => out[i];

    out[i] => panEnv[i];
    panEnv[i].attackTime(panEnvDuration);
    panEnv[i].releaseTime(panEnvDuration);
    panEnv[i].keyOn();

    panEnv[i] => dac.chan(i);
}


0.0 => float panningFrequency;

fun void shufflePan(int arr[]) {
    for (NUM_MICS - 1 => int i; i > 0; i--) {
        Math.random2(0, NUM_MICS - 1) => int j;
        arr[j] => int temp;
        arr[i] => arr[j];
        temp => arr[i];
    }

    for (0 => int i; i < NUM_MICS; i++) {
        panEnv[i].keyOff();
    }

    panEnvDuration => now;

    for (0 => int i; i < NUM_MICS; i++) {
        panEnv[i] =< dac.chan(i);
        panEnv[i] => dac.chan(arr[i]);
        panEnv[i].keyOn();
    }
}

fun void orderPan(int arr[]) {
    for (0 => int i; i < NUM_MICS; i++) {
        panEnv[i].keyOff();
    }

    panEnvDuration => now;

    for (0 => int i; i < NUM_MICS; i++) {
        panEnv[i] =< dac.chan(arr[i]);
        panEnv[i] => dac.chan(i);
        panEnv[i].keyOn();
    }
}

fun void randomPan() {
    Math.random2f(0.1, 1.0) * 4::second => dur panLength;
    int arr[NUM_MICS];
    for (0 => int i; i < NUM_MICS; i++) {
        i => arr[i];
    }
    while (true) {
        panningFrequency => float freq;
        (1.0 - freq) + panLength + panEnvDuration => dur panLength;
        if(freq > 0.1) {
            orderPan(arr);
        }

        panLength => now;

        if(freq > 0.1) {
            shufflePan(arr);
        }
        panLength => now;
    }
}

spork ~ randomPan();

// control audio -~-~-~-~-~-~-~

30 => int decibelThreshold;
1::second => dur minDecayLength;
4::second => dur maxDecayLength;

0.25::second => dur minAsymptopicLength;
1::second => dur maxAsymptopicLength;

0.5::second => dur minStretchLength;
4.5::second => dur maxStretchLength;


maxDecayLength - minDecayLength => dur decayLengthRange;
maxAsymptopicLength - minAsymptopicLength => dur asymptopicLengthRange;
maxStretchLength - minStretchLength => dur stretchLengthRange;

0 => int stretchLatch;

0 => int chunkLatch;
0 => int chunkVal;

0 => int recChunkLatch;
0 => int recChunkVal;

fun void updateAudio() {
    for (0 => int i; i < NUM_MICS; i++) {
        // input gain controls
        s[i].getEasedScaledVal() => float inGainKnob;
        in[i].gain(inGainKnob);

        s[i + 4].getEasedScaledVal() => float outGainKnob;
        out[i].gain(outGainKnob);

        // reverse controls
        k[0].getScaledVal() => float revKnob;
        rev[i].setInfluence(revKnob);
        rev[i].setReverseGain(revKnob);

        // decay controls
        k[1].getScaledVal() => float decayKnob;
        dec[i].decayGain(decayKnob);
        dec[i].length((1.0 - decayKnob) * decayLengthRange + minDecayLength);

        k[2].getEasedScaledVal() => float asyKnob;
        asy[i].gain(asyKnob);
        asy[i].length(asyKnob * asymptopicLengthRange + minAsymptopicLength);

        k[3].getEasedScaledVal() => float chpKnob;
        chp[i].gain(chpKnob);
        chp[i].density(chpKnob);

        // add a button to turn on stretching
        k[4].getScaledVal() => float strKnob;
        str[i].length(strKnob * stretchLengthRange + minStretchLength);

        k[7].getScaledVal() => panningFrequency;

        if (stretchLatch == 0 && strKnob > 0.1) {
            1 => stretchLatch;
            str[i].stretch(1);
        }

        if (stretchLatch == 1 && strKnob < 0.1) {
            0 => stretchLatch;
            str[i].stretch(0);
        }
    }
}

while (true) {
    updateControl();
    updateAudio();

    // <<< "In:", s[0].getScaledVal(), "Out:", s[4].getEasedScaledVal() >>>;

    updateDur => now;
}
