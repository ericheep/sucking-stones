// Eric Heep
// March 14th, 2017
// RandomReverse.ck

public class RandomReverse extends Chubgraph {

    inlet => LiSa mic => outlet;

    int listenOn;

    fun void listen(int l) {
        if (l == 1) {
            1 => listenOn;
            spork ~ listening();
        }
        if (l == 0) {
            0 => listenOn;
        }
    }

    fun void listening() {
        while (listenOn) {
            <<< "!" >>>;
            Math.random2f(0.1, 1.0)::second => dur bufferLength;
            record(bufferLength);
            playInReverse(bufferLength);
        }
    }

    fun void record(dur bufferLength) {
        mic.duration(bufferLength);
        mic.playPos(0::samp);
        mic.record(1);
        bufferLength => now;
        mic.record(0);
    }

    fun void playInReverse(dur bufferLength) {
        mic.play(1);
        mic.playPos(bufferLength);
        mic.rate(-1.0);
        bufferLength => now;
        mic.play(0);
    }


}

/*
RandomReverse rr;
adc => rr => dac;

rr.listen(1);

while (true ) {
    1::second => now;
}
*/
