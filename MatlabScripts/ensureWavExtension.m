function outFileName = ensureWavExtension(inFileName)
% ensure that a file name to be read or written has an extension of .wav
% needed because of audioread()/audiowrite() implementation
%
% Stuart Rosen - stuart@phon.ucl.ac.uk  September 2015

[path,name,~]=fileparts(inFileName);
outFileName=fullfile(path,[name,'.wav']);
