function testStereo(fileName)
if nargin<1
    fileName='leftFright.wav';
end
[w, SampFreq]=audioread(fileName);
playEm = audioplayer(w,SampFreq);
playblocking(playEm);

uiwait(msgbox('Stereo OK?','Test','modal'));