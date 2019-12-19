function s = myGenAudiogramSound(f, Fs, nPulses, nPulseDuration, nPulsePause, dRiseFall)
%
% modified version from GP audiometer

t = 1:round(nPulseDuration/1000*Fs);
sPulse = sin( t / Fs * 2 * pi * f );

% sPulse = addFallRise(sPulse,Fs,dRiseFall,'h');
% function s=taper(wave, rise, fall, SampFreq, type)
sPulse = taper(sPulse,dRiseFall,dRiseFall,Fs);

sPause = zeros(1, round( nPulsePause/1000 * Fs ) );

s = sPulse;
for i=1:(nPulses-1)
    s = [s sPause sPulse];
end

% figure, plot(  ((1:length(s))-1)/Fs, s)
% s = s';

