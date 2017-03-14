public class PitchedNoise extends Chubgraph {

    inlet => Noise nois => LPF lp => HPF hp => outlet;

    fun void setFreq(float freq, float decibel) {
        freq + 500 => float lowPass;
        freq - 500 => float highPass;
        lp.freq(Math.clampf(0.0, 5000, lowPass));
        hp.freq(Math.clampf(0.0, 5000, highPass));
    }

    fun void setGain(float decib) {
        nois.gain(decib * 0.5);
    }
}
