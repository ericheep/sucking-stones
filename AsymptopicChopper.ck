// Eric Heep
// March 19th, 2017
// AsymptopicChopper.ck

public class AsymptopicChopper extends Chubgraph {

    inlet => LiSa mic => outlet;

    int m_listen;
    8::second => dur buffer;

    dur m_length;

    fun void listen(int lstn) {
        if (lstn == 1) {
            1 => m_listen;
            spork ~ listening();
        }
        if (lstn == 0) {
            0 => m_listen;
        }
    }

    fun void length(dur l) {
        l => m_length;
    }

    fun void listening() {
        while (m_listen) {
            m_length => dur bufferLength;
            mic.duration(bufferLength);
            mic.playPos(0::samp);
            mic.record(1);
            bufferLength => now;
            mic.record(0);
            asymptopChop(bufferLength);
        }
    }

    fun void asymptopChop(dur bufferLength) {
        dur bufferStart;
        mic.play(1);
        while (bufferLength > 100::ms) {
            Math.random2(0, 1) => int which;
            bufferLength * 0.5 => bufferLength;
            bufferLength * which => bufferStart;
            mic.playPos(bufferStart);
            mic.rampUp(50::ms);
            bufferLength - 50::ms => now;
            mic.rampDown(50::ms);
            50::ms => now;
        }
        mic.play(0);
    }
}

/*
AsymptopicChopper a;
adc => a => dac;

a.record(1);

while (true) {
    second => now;

}
*/
