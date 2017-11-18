// Eric Heep
// November 12th, 2017
// control.ck

NanoKontrol2 n;

// breathing room -~-~-~-
<<< "MIDI Ready", "" >>>;
4::second => now;

class Slider extends MIDIValue {

}

class Knob extends MIDIValue {

}

4 => int NUM_MICS;
8 => int NUM_SLIDERS;
8 => int NUM_KNOBS;

// control -~-~-~-~-~-~-~

Slider s[NUM_SLIDERS];
Knob knobs[NUM_KNOBS];

for (0 => int i; i < NUM_SLIDERS; i++) {
    s[i].setEasingIncrement(0.005);
    knobs[i].setEasingIncrement(0.005);
}

1::ms => dur updateDur;

fun void updateControl() {
    for (0 => int i; i < NUM_SLIDERS; i++) {
         s[i].setMidiVal(n.slider[i]);
    }
    for (0 => int i; i < NUM_KNOBS; i++) {
         knobs[i].setMidiVal(n.knob[i]);
    }
}

// breathing room -~-~-~
100::ms => now;

// audio -~-~-~-~-~-~-~

HPF hp[NUM_MICS];
Decay dec[NUM_MICS];
RandomReverse rev[NUM_MICS];
AsymptopicChopper asy[NUM_MICS];
LoopingChopper chp[NUM_MICS];

Gain in[NUM_MICS];
Gain out[NUM_MICS];
Pan2 pan[NUM_MICS];

[-0.60, -0.20, 0.20, 0.60] @=> float panningPresets[];

for (0 => int i; i < NUM_MICS; i++) {
    dec[i].decays(Math.random2(6, 8));
    dec[i].length(Math.random2f(4.0, 6.0)::second);
    dec[i].mix(1.0);
    dec[i].decayGain(0.8);
    dec[i].feedback(0.0);

    rev[i].listen(1);
    asy[i].listen(1);
    chp[i].listen(1);

    // inputs in
    adc.chan(i) => hp[i] => in[i];
    hp[i].freq(200);

    // sound chain
    in[i] => rev[i] => dec[i];
    dec[i] => asy[i];
    dec[i] => chp[i];

    dec[i] => out[i];
    asy[i] => out[i];
    chp[i] => out[i];
    rev[i] => out[i];

    out[i] => pan[i] => dac;
    pan[i].pan(panningPresets[i]);

    // breathing room -~-~-~-~-
    <<< "Channel ~", i, "~ Connected", "" >>>;
}

// control audio -~-~-~-~-~-~-~

0.25::second => dur minAsymptopicLength;
1::second => dur maxAsymptopicLength;
maxAsymptopicLength - minAsymptopicLength => dur asymptopicLengthRange;

0.15::second => dur minGrainLength;
1::second => dur maxGrainLength;
maxGrainLength - minGrainLength => dur grainLengthRange;

0 => float prevDecayKnob;
0 => float prevAsyKnob;
0 => float prevRevKnob;
0 => float prevChpKnob;

fun void updateAudio() {
    for (0 => int i; i < NUM_MICS; i++) {
        // input gain controls
        s[i].getEasedScaledVal() => float inGainSlider;
        in[i].gain(inGainSlider);

        s[i + 4].getEasedScaledVal() => float outGainSlider;
        out[i].gain(outGainSlider);
    }

    // reverse controls
    knobs[0].getScaledVal() => float revKnob;
    if (revKnob != prevRevKnob) {
        for (0 => int i; i < NUM_MICS; i++) {
            rev[i].setInfluence(revKnob);
            rev[i].setReverseGain(revKnob);
        }
        revKnob => prevRevKnob;
    }

    // decay controls
    knobs[1].getScaledVal() => float decayKnob;
    if (decayKnob != prevDecayKnob) {
        for (0 => int i; i < NUM_MICS; i++) {
            dec[i].feedback(decayKnob);
        }
        decayKnob => prevDecayKnob;
    }

    // asymptopic chopper controls
    knobs[2].getEasedScaledVal() => float asyKnob;
    if (asyKnob != prevAsyKnob) {
        for (0 => int i; i < NUM_MICS; i++) {
            asy[i].gain(asyKnob);
            asy[i].length((1.0 - asyKnob) * asymptopicLengthRange + minAsymptopicLength);
        }
        asyKnob => prevAsyKnob;
    }

    // chopper controls
    knobs[3].getEasedScaledVal() => float chpKnob;
    if (chpKnob != prevChpKnob) {
        for (0 => int i; i < NUM_MICS; i++) {
            chp[i].gain(chpKnob);
            chp[i].density(chpKnob);
        }
        chpKnob => prevChpKnob;
    }
    // updatePrint(revKnob, decayKnob, asyKnob, chpKnob, panKnob);
}

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

<<< "~", "" >>>;

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
