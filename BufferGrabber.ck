// Eric Heep
// March 14th, 2017
// BufferGrabber.ck

public class BufferGrabber extends Chubgraph {

    inlet => LiSa mic => outlet;

    0 => int m_recording;
    0 => int m_playing;

    0::samp => dur m_recPos;
    100::ms => dur m_envDur;
    1::second => dur m_chunkLength;
    1::second => dur m_timeInBetween;

    40 => int m_maxChunks;
    0 => int m_currentChunks;
    m_maxChunks * m_chunkLength => dur m_maxBufferLength;

    mic.duration(m_maxBufferLength);

    fun void triggerGrab() {
        if (!m_recording && !m_playing) {
            spork ~ addToBuffer();
        }
    }

    fun void addToBuffer() {
        1 => m_recording;
        mic.record(1);
        m_chunkLength => now;
        mic.record(0);
        (m_recPos + m_chunkLength) % m_maxBufferLength => m_recPos;
        0 => m_recording;
        m_currentChunks++;
    }

    fun void playRandomChunks(int p) {
        if (p) {
            p => m_playing;
            spork ~ playingRandomChunks();
        } else {
            p => m_playing;
        }
    }

    fun void playingRandomChunks() {
        while (m_playing) {

            // chooses a random chunk
            Math.random2(0, m_currentChunks - 1) => int whichChunk;
            // chooses a random length inside of that chunk
            Math.random2f(0.5, 1.0)::m_chunkLength => dur randChunkLength;
            // finds the offset to center that chunk
            (m_chunkLength - randChunkLength) * 0.5 => dur chunkOffset;

            (whichChunk + 1) * m_chunkLength => dur endPos;
            endPos - randChunkLength - chunkOffset => dur startPos;

            // play the chunk
            mic.playPos(startPos);
            mic.play(1);
            mic.rampUp(m_envDur);
            randChunkLength -  m_envDur => now;
            mic.rampDown(m_envDur);
            m_envDur => now;
            mic.play(0);

            Math.random2f(0.2, 0.4)::m_timeInBetween => now;
        }
    }
}

adc => BufferGrabber b => dac;

b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;
b.triggerGrab();
2::second => now;

b.playRandomChunks(1);

while (true) {
    second => now;
}



