function [InRMS, OutRMS] = SetLevels(VolumeSettingsFile)
%
% Routine to set levels at the beginning of a test
%
% Version 1.0 July 2011
% Version 2.0 September 2011
%   version specific for SentInNoise
% Version 3.0 May 2012
%   allow use of the babyface
% Version 4.0 January 2013
%   specify explicitly in VolumeSettings.txt file what kind of system is
%   being used. Current options
%       baby
%       W7
%       XP
%
% Stuart Rosen - stuart@phon.ucl.ac.uk
%

%% Settings for level
% ensure the file is avilable
if exist(VolumeSettingsFile,'file')
    [SoundCard, SoundMasterLevel,SoundWaveLevel,InRMS,OutRMS]=textread(VolumeSettingsFile,'%s %f %f %f %f',1);
else
    FileMissingErrorMessage=sprintf('Missing file: %s does not exist', VolumeSettingsFile);
    h=msgbox(FileMissingErrorMessage, 'Missing file', 'error', 'modal'); uiwait(h);
    error(FileMissingErrorMessage);
end

%% set the volume controls on the basis of the SoundCard specified in VolumeSettingsFile
if strcmp(SoundCard, 'baby')  % need CoreAudioApi.dll for Windows 7 & Vista
    sendRMEmessage(0,7,SoundMasterLevel);
    SetMatlabVolume(SoundWaveLevel);
elseif strcmp(SoundCard, 'W7') % this is not Windows XP
    system(sprintf('SetWindowsVolume.exe %f',SoundMasterLevel));
    SetMatlabVolume(SoundWaveLevel);
elseif strcmp(SoundCard, 'XP') % Windows XP
    % need a VB .dll for this
    objSC= actxserver('SoundControl.General');
    invoke(objSC,'SetMasterLevel',SoundMasterLevel);
    invoke(objSC,'SetWaveLevel',SoundWaveLevel);
else
    error('Illegal sound card value of %s specified in %s', ...
        char(SoundCard), VolumeSettingsFile)
end


