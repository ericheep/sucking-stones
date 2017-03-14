// Eric Heep
// March 14th, 2017
// AsymptopicChopper.ck

public class AsymptopicChopper extends Chubgraph {

    inlet => LiSa mic => outlet;

    int recOn;

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
        y - x => recTime;
        mic.record(0);
    }

    fun void play(int ply) {
        if (ply == 1) {
            1 => playOn;
            spork ~
        }
    }


}
