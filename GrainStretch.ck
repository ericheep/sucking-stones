// Eric Heep
// March 14th, 2017
// GrainStretch.ck

public class GrainStretch extends Chubgraph {

    inlet => LiSa mic => ADSR env => ADSR arc => outlet;

    0 => int m_stretching;
    0 => int m_whichMic;
    2.0::second => dur m_length;

    fun void stretch(int s) {
        if (s == 1) {
            1 => m_stretching;
            spork ~ stretching();
        }
        else {
            0 => m_stretching;
        }
    }

    fun void length(dur l) {
        l => m_length;
    }

    fun void cueArc(dur bufferLength) {
        bufferLength/16.0 => dur envLength;
        arc.attackTime(envLength);
        arc.releaseTime(envLength);
        arc.keyOn();
        bufferLength - envLength => now;
        arc.keyOff();
        envLength => now;
    }

    fun void stretching() {
        while (m_stretching) {
            recordVoice(m_length);
            m_length * Math.random2f(2.0, 4.0) => dur stretchLength;
            spork ~ cueArc(stretchLength);
            stretchVoice(m_length, stretchLength, 64);
        }
    }

    fun void recordVoice(dur duration) {
        mic.duration(duration);
        mic.record(1);
        duration => now;
        mic.record(0);
    }

    // all the sound stuff we're doing
    fun void stretchVoice(dur duration, dur stretchRate, int windows) {
        stretchRate/windows => dur grain;
        grain * 0.5 => dur halfGrain;

        // for some reason if you try to put a sample
        // at a fraction of samp, it will silence ChucK
        if (halfGrain < 1.0::samp) {
            return;
        }

        halfGrain/32.0 => dur halfGrainEnv;

        // envelope parameters
        env.attackTime(halfGrainEnv);
        env.releaseTime(halfGrainEnv);

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
                halfGrain - halfGrainEnv => now;
            }
            else {
                grain => now;
            }
        }

        mic.play(0);
    }
}

/*
adc => GrainStretch g => dac;
adc => Gain gr => dac;

g.stretch(1);

while(true) {
    samp => now;
}
*/
