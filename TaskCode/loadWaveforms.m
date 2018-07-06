function loadWaveforms(duration)

WaveGen = BpodAudioPlayer('COM4');
WaveGen.TriggerMode = 'Normal';
WaveGen.SamplingRate = 96000;
WaveGen.AMenvelope = (0.005:0.005:1);


%Load waveform 1
Frequency = 6000;
Amplitude = 1;

t = 0:1/WaveGen.SamplingRate:duration;
wave1 = Amplitude*sin(2*pi*Frequency*t);
WaveGen.loadSound(1,wave1);

%Load waveform 2
Frequency = 10000;
Amplitude = 0.6;

t = 0:1/WaveGen.SamplingRate:duration;
wave2 = Amplitude*sin(2*pi*Frequency*t);
WaveGen.loadSound(2,wave2);

%Load waveform 3
Frequency = 20000;
Amplitude = 1.5;

t = 0:1/WaveGen.SamplingRate:duration;
wave3 = Amplitude*sin(2*pi*Frequency*t);
WaveGen.loadSound(3,wave3);

%Load waveform 4
Frequency = 25000;
Amplitude = 0.9;

t = 0:1/WaveGen.SamplingRate:duration;
wave4 = Amplitude*sin(2*pi*Frequency*t);
WaveGen.loadSound(4,wave4);

end
