/*4 => int NUM_MICS;

Gain g[4];

for (int i; i < NUM_MICS; i++) {
    adc.chan(i) => g[i] => dac.chan(i);
}

while (true) {
    1::second => now;
}*/

4 => int NUM_MICS;


int arr[NUM_MICS];

fun void shuffle(int arr[]) {
    for (NUM_MICS - 1 => int i; i > 0; i--) {
        Math.random2(0, NUM_MICS - 1) => int j;
        arr[j] => int temp;
        arr[i] => arr[j];
        temp => arr[i];
    }
}

for (0 => int i; i < arr.size(); i++) {
    i => arr[i];
}

<<< arr[0],arr[1],arr[2],arr[3] >>>;

shuffle(arr);

<<< arr[0],arr[1],arr[2],arr[3] >>>;




