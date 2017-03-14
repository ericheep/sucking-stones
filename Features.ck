public class Features {

    inlet => FFT fft => blackhole;
    fft =^ RMS rms;

    256 => int N => fft.size;
    N => int hop;

    Noise noise => HPF hp => LPF lp => outlet;
    //CNoise noise => LPF lp => outlet;

    Windowing.hamming(N) => fft.window;
    UAnaBlob fftBlob;
    UAnaBlob rmsBlob;
    float spreadVal, centroidVal;
    second/samp => float sr;
    sr/2.0 => float nyquist;

    1 => int listening;

    fun listen() {
        while (listening) {
            rms.upchuck() @=> rmsBlob;
            fft.upchuck() @=> fftBlob;

            hop::samp => now;

            spread(fftBlob.fvals(), sr, N) => spreadVal;
            centroid(fftBlob.fvals(), sr, N) => centroidVal;
            rmsBlob.fval(0) * 250 => dbVal;

            Math.fabs(centroidVal + (spreadVal/2.0)) => lowPass;
            Math.fabs(centroidVal - (spreadVal/2.0)) => highPass;

            if (dbVal > 0 || dbVal < 1.0) {
                noise.gain(dbVal);
            }
            if (lowPass > 0 && lowPass < 8000) {
                lp.freq(lowPass);
            }
            if (highPass > 0 && highPass < 8000) {
                hp.freq(highPass);
            }
        }
    }

    // spectral centroid
    fun float centroid(float X[], float sr, int fft_size) {

        // array for our bin frequencies
        float fft_frqs[fft_size/2 + 1];

        // finds center bin frequencies

        for (int i; i < fft_frqs.cap(); i++) {
            sr/fft_size * i => fft_frqs[i];
        }

        float den;
        float power[X.cap()];
        for (int i; i < X.cap(); i++) {
            X[i] * X[i] => power[i];
            power[i] +=> den;
        }

        float num;
        for (int i; i < X.cap(); i++) {
            fft_frqs[i] * power[i] +=> num;
        }

        return num/den;
    }

    // spectral spread
    fun float spread(float X[], float sr, int fft_size) {

        // required centroid for spread
        centroid(X, sr, fft_size) => float cent;

        // array for our bin frequencies
        float fft_frqs[fft_size/2 + 1];

        // finds center bin frequencies
        for (int i; i < fft_frqs.cap(); i++) {
            sr/fft_size * i => fft_frqs[i];
        }

        float num, den;
        float power[X.cap()];
        float square[X.cap()];

        for(int i; i < X.cap(); i++) {
            X[i] * X[i] => power[i];
            Math.pow(fft_frqs[i] - cent, 2) => square[i];
            power[i] * square[i] +=> num;
            power[i] +=> den;
        }
        return Math.sqrt(num/den);
    }
}

adc => FFTNoise fft => dac;
fft.listen(1);

while (true) {
    1::second => now;
}
