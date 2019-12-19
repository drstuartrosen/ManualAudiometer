function playback(g)

% Vs 2.5 - April 2019
%   catch errors when stimulus level specified cannot be reached
% Vs 2.0 - April 2019
%   call with structure of all relevant variables!

% dur  - duration of tone (s)

risefall=50; % (ms) SR

if g.usePlayrec == 1
    fs=96000;   % sampling frequency
    PrePostPulseSilence=.05; % in seconds
else
    fs=44100;   % sampling frequency
    PrePostPulseSilence=.1; % in seconds
end

if strcmpi(g.correctionType,'SPL')
    if (g.channel == 0)
        HL_correction=g.HL_correctionLeft;
    elseif (g.channel == 1)
        HL_correction=g.HL_correctionRight;
    else
        error('channel must be 0 or 1');
    end
elseif strcmpi(g.correctionType,'FPL')
elseif strcmpi(g.correctionType,'SPL-FREx')
else
    error('correctionType must be one of SPL, SPL-FREx or FPL');
end

if g.numPulses==1
    t = [0:1/fs:g.nPulseDuration/1000];
    SineWave=sin(2*pi*g.tone*t);
    SineWave=taper(SineWave,risefall,risefall,fs);
    % function s=taper(wave, rise, fall, SampFreq, type)
else
    % function s = genAudiogramSound(f, Fs, nPulses, nPulseDuration, nPulsePause, dRiseFall)
    SineWave=myGenAudiogramSound(g.tone,fs,g.numPulses,g.nPulseDuration,g.nPulsePause,risefall);
end

if strcmpi(g.correctionType,'SPL')
    SineWave=SineWave*(10^(HL_correction/20))*(10^(g.att/20));
else
    if strcmpi(g.correctionType,'SPL-FREx')
        [SineWave,a,errors] = SPLFREx_applyAtt(g.maxSPLs, g.att + TimsMAP(g.tone),g.tone,SineWave);
    elseif strcmpi(g.correctionType,'FPL')
        % function [stimScaled,a,errors] = ARLas_applyISC(isc,targetLvl,type,f,stim)
        [SineWave,a,errors] = ARLas_applyISC(g.FPLcorrection.t, g.att + TimsMAP(g.tone),'fpl',g.tone,SineWave);
    end
    if errors % need to warn user!
        % which button has been pressed?
        hx = findobj(g.figure1,'Value',1);
        currentBackgroundColor=get(hx,'BackgroundColor');
        set(hx,'BackgroundColor',[1 0 0]);
        % currentBackgroundColor=g.pushbutton50dB.BackgroundColor;
        % g.pushbutton50dB.BackgroundColor=[1 0 0];
        pause(0.3)
        % set(hx,'BackgroundColor', currentBackgroundColor);
        set(hx,'BackgroundColor', [.94 .94 .94]);
        set(hx,'Value',0);
        pause(.2)
        % g.pushbutton50dB.BackgroundColor=currentBackgroundColor;
    end
end

%%

SineWave=[zeros(1,round(PrePostPulseSilence*fs)) taper(SineWave,risefall,risefall,fs) zeros(1,round(PrePostPulseSilence*fs))];
if g.channel==1 % right channel
    y=[zeros(1,length(SineWave))' SineWave'];
else    % left channel
    y=[SineWave' zeros(1,length(SineWave))'];
end

if g.usePlayrec == 1
    % Get audio device ID based on the USB name of the device.
    dev = playrec('getDevices');
    d = find( cellfun(@(x)isequal(x,'ASIO Fireface USB'),{dev.name}) ); % find device of interest - RME FireFace channels 3+4
    playDeviceInd = dev(d).deviceID;
    recDeviceInd = dev(d).deviceID;
    
    % playrec
    if playrec('isInitialised')
        playrec('reset');
    end
    playrec('init', fs, playDeviceInd, recDeviceInd);
    playrec('play', y, [1,2]);
elseif g.usePlayrec == 0
    playEm = audioplayer(y,fs);
    playblocking(playEm);
    %play(playEm);
    play(playEm);
else
    error('value of usePlayrec must be 0 or 1');
end
% pause(1.5)

