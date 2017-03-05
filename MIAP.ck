// Eric Heep

// Manifold-Something Amplitude Panning
// white paper locked behind AES paywall

public class MIAP {

    // our node objects
    class Node {
        float coordinate[2];
        float gain;

        int index, active;
    }

    // our triset objects
    class Triset {
        int nodeId[3];

        // the node reference
        float coordinate[3][2];
        float gain[3];

        int index, active;

        // area of the triangle
        float area;
        float areaScalar;

        // length of the sides of the triangle
        float ab, bc, ca;
    }

    Node nodes[0];
    Triset trisets[0];

    int numNodes;
    int numTrisets;

    private void init() {
        0 => numNodes;
        0 => numTrisets;
    }

    init();

    public int addNode(float coordinate[]) {
        Node node;
        coordinate @=> node.coordinate;
        // trisets @=> node.trisets;
        numNodes => node.index;

        nodes << node;
        numNodes++;

        return node.index;
    }

    public int addTriset(int n1, int n2, int n3) {
        Triset triset;

        nodes[n1].coordinate @=> triset.coordinate[0];
        nodes[n2].coordinate @=> triset.coordinate[1];
        nodes[n3].coordinate @=> triset.coordinate[2];

        n1 => triset.nodeId[0];
        n2 => triset.nodeId[1];
        n3 => triset.nodeId[2];

        distance(nodes[n1].coordinate, nodes[n2].coordinate) => triset.ab;
        distance(nodes[n2].coordinate, nodes[n3].coordinate) => triset.bc;
        distance(nodes[n3].coordinate, nodes[n1].coordinate) => triset.ca;

        heronArea(triset.ab, triset.bc, triset.ca) => triset.area;
        1.0/triset.area => triset.areaScalar;

        numTrisets => triset.index;
        trisets << triset;
        numTrisets++;

        return triset.index;
    }

    private void clearActiveTrisets() {
        for (0 => int i; i < numTrisets; i++) {
            0 => trisets[i].active;
        }
    }

    public void setPosition(float pos[]) {
        clearActiveTrisets();
        for (0 => int i; i < numTrisets; i++) {
            if (pointInTriset(pos, trisets[i])) {
                1 => trisets[i].active;
                setTrisetNodes(pos, trisets[i]);
                break;
            }
        }
    }


    private void setTrisetNodes(float pos[], Triset triset) {
        distance(triset.coordinate[0], pos) => float ap;
        distance(triset.coordinate[1], pos) => float bp;
        distance(triset.coordinate[2], pos) => float cp;

        heronArea(triset.ab, bp, ap) => float n3Area;
        heronArea(triset.ca, ap, cp) => float n2Area;
        triset.area - n3Area - n2Area => float n1Area;

        Math.sqrt(n1Area * triset.areaScalar) => triset.gain[0];
        Math.sqrt(n2Area * triset.areaScalar) => triset.gain[1];
        Math.sqrt(n3Area * triset.areaScalar) => triset.gain[2];

        triset.gain[0] => nodes[triset.nodeId[0]].gain;
        triset.gain[1] => nodes[triset.nodeId[1]].gain;
        triset.gain[2] => nodes[triset.nodeId[2]].gain;
    }

    private float heronArea(float A, float B, float C) {
        (A + B + C) * 0.5 => float S;
        return Math.sqrt(S * (S - A) * (S - B) * (S - C));
    }

    private float distance(float A[], float B[]) {
        return Math.sqrt(Math.pow((B[0] - A[0]), 2) + Math.pow((B[1] - A[1]), 2));
    }


    // http://blackpawn.com/texts/pointinpoly/
    private int pointInTriset(float P[], Triset triset) {

        // pull our coordinates out
        triset.coordinate[0] @=> float A[];
        triset.coordinate[1] @=> float B[];
        triset.coordinate[2] @=> float C[];

        // compute vectors
        computeVector(C, A) @=> float v0[];
        computeVector(B, A) @=> float v1[];
        computeVector(P, A) @=> float v2[];

        // compute dot products
        dotProduct(v0, v0, 2) => float dot00;
        dotProduct(v0, v1, 2) => float dot01;
        dotProduct(v0, v2, 2) => float dot02;
        dotProduct(v1, v1, 2) => float dot11;
        dotProduct(v1, v2, 2) => float dot12;

        // compute barycentric coordinates
        1.0/(dot00 * dot11 - dot01 * dot01) => float invDenom;
        (dot11 * dot02 - dot01 * dot12) * invDenom => float u;
        (dot00 * dot12 - dot01 * dot02) * invDenom => float v;

        // check if point is in triangle
        return (u >= 0) && (v >= 0) && ((u + v) < 1);
    }

    private float[] computeVector(float R[], float S[]) {
        return [R[0] - S[0], R[1] - S[1]];
    }

    private float dotProduct(float v[], float u[], int n) {
        0.0 => float result;

        for (0 => int i; i < n; i++) {
            v[i]*u[i] +=> result;
        }

        return result;
    }

    // helpful functions for visualizing MIAP
    public int getActiveTriset() {
        for (0 => int i; i < numTrisets; i++) {
            if (trisets[i].active == 1) {
                return trisets[i].index;
            }
        }
        return -1;
    }

    public float[][] getActiveCoordinates() {
        getActiveTriset() => int idx;;
        return [trisets[idx].coordinate[0], trisets[idx].coordinate[1], trisets[idx].coordinate[2]];
    }

    public float[] getActiveGains() {
        getActiveTriset() => int idx;
        return [trisets[idx].gain[0], trisets[idx].gain[1], trisets[idx].gain[2]];
    }
}

/*
MIAP m;
float activeCoordinates[][];

[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0]] @=> float coordinates[][];

// bottom row, silent
m.addNode([0.0, 0.0]);
m.addNode([1.0, 0.0]);
m.addNode([0.0, 1.0]);
m.addNode([1.0, 1.0]);

// the three nodes that make up a triset
m.addTriset(0, 1, 2);
m.addTriset(1, 2, 3);

m.setPosition([0.0, 0.1]);

<<< m.getActiveTriset() >>>;
<<< m.getActiveCoordinates()[0][0], m.getActiveCoordinates()[0][1] >>>;
<<< m.getActiveCoordinates()[1][0], m.getActiveCoordinates()[1][1] >>>;
<<< m.getActiveCoordinates()[2][0], m.getActiveCoordinates()[2][1] >>>;
<<< m.getActiveGains()[0], m.getActiveGains()[1], m.getActiveGains()[2]>>>;
*/
