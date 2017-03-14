// Eric Heep
// March 14th, 2017
// AsymptopicChopper.ck

public class AsymptopicChopper extends Chubgraph {

    inlet => LiSa mic => outlet;

    int recOn;
    8::second => dur buffer;

    fun void record(int rcrd) {
        if (rcrd == 1) {
            spork ~ recording();
        }
        if (rcrd == 0) {
            0 => recOn;
        }
    }

    fun void recording() {
        1 => recOn;
        mic.duration(buffer);
        mic.playPos(0::samp);
        mic.record(1);
        now => time x;
        while (recOn == 1) {
            samp => now;
        }
        now => time y;
        y - x => dur recTime;
        mic.record(0);
        asymptopChop(recTime);
    }

    fun void asymptopChop(dur bufferLength) {
        dur bufferStart;
        mic.play(1);
        while (bufferLength > 0.1::samp) {
            Math.random2(0, 1) => int which;
            bufferLength * 0.5 => bufferLength;

            bufferLength * which => bufferStart;

            mic.playPos(bufferStart);
            bufferLength => now;
        }
        mic.play(0);
    }


}

AsymptopicChopper a;
adc => a => dac;
a.record(1);
14::second => now;
a.record(0);
15::second => now;
