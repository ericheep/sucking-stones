// I just want to know that I'm not crazy,
// so I'm going to show it all in Processing

OscOut out;
out.dest("127.0.0.1", 12000);

MIAP m;

/*

    For four speaker nodes with a perimeter of silent nodes.

        *-----*-----*

        ---0-----1---

        *-----*-----*

        ---2-----3---

        *-----*-----*

*/

// first row, silent nodes
m.addNode([0.5, 0.0]);

// second row, speaker nodes
m.addNode([0.25, 0.25]);
m.addNode([0.75, 0.25]);

// third row, silent nodes
m.addNode([0.0, 0.5]);
m.addNode([0.5, 0.5]);
m.addNode([1.0, 0.5]);

// fourth row, speaker nodes
m.addNode([0.25, 0.75]);
m.addNode([0.75, 0.75]);

// fifth row, silent nodes
m.addNode([0.5, 1.0]);

m.addTriset(0, 1, 2);
m.addTriset(1, 3, 4);
m.addTriset(1, 2, 4);
m.addTriset(2, 4, 5);
m.addTriset(3, 4, 6);
m.addTriset(4, 6, 7);
m.addTriset(4, 5, 7);
m.addTriset(6, 7, 8);

SinOsc sin1 => blackhole;
SinOsc sin2 => blackhole;
sin1.freq(0.1512/3);
sin2.freq(0.27/3);

fun void oscSender(float xPos, float yPos) {
    out.start("/pos");
    out.add(xPos);
    out.add(yPos);
    out.send();

    for (0 => int i; i < m.nodes.size(); i++) {
        out.start("/coord");
        out.add(i);
        out.add(m.nodes[i].coordinate[0]);
        out.add(m.nodes[i].coordinate[1]);
        out.send();

        // <<< m.nodes[i].coordinate[1], m.nodes[i].coordinate[1] >>>;
        out.start("/gain");
        out.add(i);
        out.add(m.nodes[i].gain);
        out.send();
    }

    if (m.getActiveTriset() > 0) {
        m.getActiveCoordinates() @=> float c[][];

        for (0 => int i; i < c.size(); i++) {
            out.start("/activeCoord");
            out.add(i);
            out.add(c[i][0]);
            out.add(c[i][1]);
            out.send();
        }
    }
}

while (true) {
    (((sin1.last() + 1.0) * 0.5) * 0.5) + .25 => float xPos;
    (((sin2.last() + 1.0) * 0.5) * 0.5) + .25 => float yPos;
    m.setPosition([xPos, yPos]);
    oscSender(xPos, yPos);
    second/120.0 => now;
}
