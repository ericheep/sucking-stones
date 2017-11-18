// Eric Heep
// November 12th, 2017
// run.ck

// communication class
Machine.add(me.dir() + "NanoKontrol2.ck");

// audio classes
Machine.add(me.dir() + "RandomReverse.ck");
Machine.add(me.dir() + "Decay.ck");
Machine.add(me.dir() + "AsymptopicChopper.ck");
Machine.add(me.dir() + "LoopingChopper.ck");
Machine.add(me.dir() + "GrainStretch.ck");

100::ms => now;

// midi value
Machine.add(me.dir() + "MIDIValue.ck");

// control class
Machine.add(me.dir() + "control-two-channel.ck");
