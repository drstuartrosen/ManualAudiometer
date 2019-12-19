function [stimScaled,a,errors] = SPLFREx_applyAtt(isc,targetLvl,f,stim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Modified from
% [stimScaled,a,errors] = ARLas_applyISC(isc,targetLvl,type,f,stim);
%
% Apply given calibration to a stimulus.
%
% INPUT ARGUMENTS:
% calValue = calibration matrix
% targetLvl = desired stimulus level (dB SPL)
% f = frequency of stimulus (Hz)
% stim = stimulus of unit amplitude (i.e. full output)
%
% OUTPUT ARGUMENTS:
% stimScaled = stimulus scaled to give target level
% a = multiplier used to scale stimulus
%       if narrowband stimulus, a is scalar; if broadband a is impulse
%       response vector
% errors = report of whether target can be reached (1) or not (0).
%       SR: actually, d is a positive number which is the amount that the
%       signal would need to be amplified in order to reach the specified
%       level
%
% Stuart Rosen April 2019
%
% Auditory Research Lab, The University of Iowa
% Deptartment of Communication Sciences & Disorders
% The University of Iowa
% Author: Shawn Goodman
% Date: December 1, 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning off backtrace

stimScaled = [];
a = [];
errors = [];

fo = interp1(isc(:,1),isc(:,2),f,'pchip');
d = targetLvl - fo; % calculate the dB difference between full out and desired (target) level
a = 10^(d/20); % express dB difference as a linear multiplier
if a >= 1 % if cannot achieve target output because desired > than full out
    a = 0.999; % set multiplier to full out
    errors = d; % error is the dB amount that exceeds full out
    warning('cannot achieve target output because desired > full out')
else
    errors = 0;
end
stimScaled = stim * a;

