// Eric Heep
// March 14th, 2017
// GrainStretch.ck

public class GrainStretch extends Chubgraph {

    inlet => LiSa mic => ADSR env => outlet;

    0 => int m_stretching;
    0 => int m_whichMic;
    3.0::second => dur m_duration;

    fun void stretch(int s) {
        if (s == 1) {
            1 => m_stretching;
            spork ~ stretching();
        }
        else {
            0 => m_stretching;
        }
    }

    fun void stretching() {
        Math.random2f(0.5, 1.0) * m_duration => dur length;
        while (m_stretching) {
            recordVoice(length);
            stretchVoice(length, Math.random2f(0.2, 0.7), 64);
        }
    }

    fun void recordVoice(dur duration) {
        mic.duration(duration * 4);
        mic.record(1);
        duration => now;
        mic.record(0);
    }

    // all the sound stuff we're doing
    fun void stretchVoice(dur duration, float rate, int windows) {
        (duration * (1.0/rate))/windows => dur grain;
        grain * 0.5 => dur halfGrain;

        // for some reason if you try to put a sample
        // at a fraction of samp, it will silence ChucK
        if (halfGrain < 1.0::samp) {
            return;
        }

        // envelope parameters
        env.attackTime(halfGrain);
        env.releaseTime(halfGrain);

        halfGrain/samp => float halfGrainSamples;
        ((duration/samp)$int)/windows => int sampleIncrement;

        mic.play(1);

        // bulk of the time stretching
        for (0 => int i; i < windows; i++) {
            mic.playPos((i * sampleIncrement)::samp);
            (i * sampleIncrement)::samp + grain => dur end;

            // only fade if there will be no discontinuity errors
            if (end < duration) {
                env.keyOn();
                halfGrain => now;
                env.keyOff();
                halfGrain => now;
            }
            else {
                grain => now;
            }
        }

        mic.play(0);
    }
}

adc => GrainStretch g => dac;

g.stretch(1);

while(true) {
    samp => now;
}
