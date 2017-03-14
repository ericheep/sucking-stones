public class PitchedNoise extends Chubgraph {

    inlet => Noise nois => LPF lp => HPF hp => outlet;

    fun void setFreq(float freq, float decibel) {
        freq + 500 => float lowPass;
        freq - 500 => float highPass;

        if (decibel > 0 || decibel < 1.0) {
            noise.gain(decibel * 0.5);
        }
        if (lowPass > 0 && lowPass < 5000) {
            lp.freq(lowPass);
        }
        hp.freq(Math.clampf(0.0, 5000, highPass));
    }
}
