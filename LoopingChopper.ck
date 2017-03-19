// Eric Heep
// March 18th, 2017
// LoopingChopper.ck

public class LoopingChopper extends Chubgraph {

    LiSa mic[2];
    inlet => mic[0] => outlet;
    inlet => mic[1] => outlet;

    0 => int recOn;
    4 => int m_numChops;
    4 => int m_minChops;
    24 => int m_maxChops;
    m_maxChops - m_minChops => int m_chopRange;
    0 => int m_listen;

    fun void setMinChops(int min) {
        min => m_minChops;
        m_maxChops - m_minChops => m_chopRange;

    }

    fun void setMaxChops(int max) {
        max => m_maxChops;
        m_maxChops - m_minChops => m_chopRange;
    }

    fun void density(float d) {
        (d * m_chopRange)$int + m_minChops => m_numChops;
    }

    fun void listen(int lstn) {
        if (lstn == 1) {
            1 => m_listen;
            spork ~ recording();
        }
        if (lstn == 0) {
            0 => m_listen;
        }
    }

    fun void recording() {
        0 => int idx;
        1::second => dur bufferLength;
        while (m_listen) {
            mic[idx].duration(bufferLength);
            mic[idx].playPos(0::samp);
            mic[idx].record(1);
            bufferLength => now;
            mic[idx].record(0);
            spork ~ chopper(mic[idx], bufferLength);
            (idx + 1) % 2 => idx;
        }
    }

    fun void chopper(LiSa mic, dur bufferLength) {
        mic.play(1);
        m_numChops => int numChops;
        bufferLength/(numChops$float) => dur chopLength;
        for (0 => int i; i < numChops; i++) {
            Math.random2(0, numChops - 1) * chopLength => dur playPos;
            mic.rampUp(20::ms);
            mic.playPos(playPos);
            chopLength - 20::ms => now;
            mic.rampDown(20::ms);
            20::ms => now;
        }
        mic.play(0);
    }


}
/*
LoopingChopper l;
adc => l => dac;

l.record(1);
l.density(1.0);

while (true) {
    second => now;

}
*/
