// Eric Heep
// March 13th, 2017
// control.ck

NanoKontrol2 n;

// breathing room -~-~-~-
<<< "MIDI Ready", "" >>>;
4::second => now;

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
    s[i].setEasingIncrement(0.005);
    k[i].setEasingIncrement(0.005);
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

// breathing room -~-~-~
100::ms => now;

// audio -~-~-~-~-~-~-~

4 => int NUM_MICS;

HPF hp[NUM_MICS];
Decay dec[NUM_MICS];
RandomReverse rev[NUM_MICS];
AsymptopicChopper asy[NUM_MICS];
LoopingChopper chp[NUM_MICS];

ADSR panEnv[NUM_MICS];

Gain in[NUM_MICS];
Gain out[NUM_MICS];

10::ms => dur panEnvDuration;

for (0 => int i; i < NUM_MICS; i++) {
    dec[i].decays(6);
    dec[i].length(3::second);
    dec[i].mix(1.0);
    dec[i].decayGain(1.0);
    dec[i].feedback(0.0);

    rev[i].listen(1);
    asy[i].listen(1);
    chp[i].listen(1);

    // inputs in
    adc.chan(i) => hp[i] => in[i];
    hp[i].freq(2000);

    // sound chain
    in[i] => rev[i] => dec[i];
    dec[i] => asy[i];
    dec[i] => chp[i];

    dec[i] => out[i];
    asy[i] => out[i];
    chp[i] => out[i];
    rev[i] => out[i];

    out[i] => panEnv[i] => dac.chan(i);

    panEnv[i].attackTime(panEnvDuration);
    panEnv[i].releaseTime(panEnvDuration);
    panEnv[i].keyOn();

    // breathing room -~-~-~-~-
    <<< "Channel ~", i, "~ Connected", "" >>>;
}

// control audio -~-~-~-~-~-~-~

0.25::second => dur minAsymptopicLength;
1::second => dur maxAsymptopicLength;

maxAsymptopicLength - minAsymptopicLength => dur asymptopicLengthRange;
0 => int panLatch;

0.0 => float panningFrequency;

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
        dec[i].feedback(decayKnob);

        k[2].getEasedScaledVal() => float asyKnob;
        asy[i].gain(asyKnob);
        asy[i].length(asyKnob * asymptopicLengthRange + minAsymptopicLength);

        k[3].getEasedScaledVal() => float chpKnob;
        chp[i].gain(chpKnob);
        chp[i].density(chpKnob);

        // add a button to turn on stretching
        k[4].getScaledVal() => float panKnob;
        panKnob => panningFrequency;

        updatePrint(revKnob, decayKnob, asyKnob, chpKnob, panKnob);
    }
}

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

        (1.0 - freq) * panLength + panEnvDuration => dur panLength;

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

// uiPrint, for sanity -~-~-~-~-~-~-~

string uiPrintOutput;
string prevUiPrintOutput;
["~", "*", "-"] @=> string possibilities[];

fun void updatePrint(float rev, float dec, float asy, float chp, float pan)
{
    string temp;
    " | Rev: " + format(rev) + " " + uiFiller(rev) + " " +=> temp;
    " Dec: " + format(dec) + " " + uiFiller(dec) + " " +=> temp;
    " Asy: " + format(asy) + " " + uiFiller(asy) + " " +=> temp;
    " Chp: " + format(chp) + " " + uiFiller(chp) + " " +=> temp;
    " Pan: " + format(pan) + " " + uiFiller(pan) + " " + "|" +=> temp;
    temp => uiPrintOutput;
}

fun string uiFiller(float f) {
    string filler;
    for (0 => int i; i < 28; i++) {
        if (Math.random2f(0.0, 1.0) < f) {
            possibilities[Math.random2(0, possibilities.size() - 1)] +=> filler;
        }
        else {
            " " +=> filler;
        }
    }
    return filler;
}

fun string format(float val) {
    " " => string p;
    return (val + p).substring(0, 4);
}

<<< "-~-~-~-~-~    -~-~-~-~-~    -~-~-~-~-~    -~-~-~-~-~    -~-~-~-~-~    -~-~-~-~-~", "" >>>;

fun void uiPrint() {
    while (true) {
        0.5::second => now;
        if (uiPrintOutput != prevUiPrintOutput) {
            <<< uiPrintOutput, "" >>>;
            uiPrintOutput => prevUiPrintOutput;
        }
    }
}

spork ~ uiPrint();

while (true) {
    updateControl();
    updateAudio();

    updateDur => now;
}
