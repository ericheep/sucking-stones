// Eric Heep
// March 14th, 2017
// PitchedNoise.ck


public class PitchedNoise extends Chubgraph {

    Noise nois => LPF lp => HPF hp => outlet;

    fun void setFreq(float freq) {
        freq + 10.0 => float lowPass;
        freq - 10.0 => float highPass;
        lp.freq(Std.clampf(0.0, 5000.0, lowPass));
        hp.freq(Std.clampf(0.0, 5000.0, highPass));
    }

    fun void setInputGain(float rms) {
        nois.gain(rms * 0.5);
    }
}
