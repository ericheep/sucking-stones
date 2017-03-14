// Eric Heep
// March 13th, 2017
// Decibel.ck

// class that analyzes indivdual channels and returns
// information about them

public class Decibel extends Chubgraph {

    inlet => Gain g => OnePole p => blackhole;
    inlet => g;

    // rms stuff
    3 => g.op;
    0.994=> p.pole;

    fun void setPole(float pole) {
        pole => p.pole;
    }

    fun float rms() {
        return p.last();
    }

    fun float decibel() {
        return Std.rmstodb(p.last());
    }

    // merely holds until a spike is heard above a certain level
    fun void decibelOver(float db) {
        while (decibel() < db) {
            1::samp => now;
        }
    }

    fun void decibelUnder(float db) {
        while (decibel() > db) {
            1::samp => now;
        }
    }
}
