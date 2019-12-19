function [stimScaled,a,errors] = ARLas_applyISC(isc,targetLvl,type,f,stim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [stimScaled,a,errors] = ARLas_applyISC(isc,targetLvl,type,f,stim);
%
% Apply in-situ calibration to a stimulus.
% 
% INPUT ARGUMENTS:
% isc = in-situ calibration structure obtained using ARLas_insituCal.m
% targetLvl = desired stimulus level (dB SPL)
% type = type of calibration to apply ('spl','fpl','rpl',ipl')
% f = dominant frequency of stimulus (Hz) -- for narrowband stimuli
%        -- for broadband stimuli, give value of open set ([])
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
% Auditory Research Lab, The University of Iowa
% Deptartment of Communication Sciences & Disorders
% The University of Iowa
% Author: Shawn Goodman
% Date: December 1, 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

stimScaled = [];
a = [];
errors = [];

if ~isempty(f) % if the stimulus is narrowband
    % get the full-out amplitude from the in-situ cal measurement
    if strcmp(type,'spl')
        fo = interp1(isc.freq,isc.spl,f,'pchip');
    elseif strcmp(type,'fpl')
        fo = interp1(isc.freq,isc.fpl,f,'pchip');
    elseif strcmp(type,'rpl')
        fo = interp1(isc.freq,isc.rpl,f,'pchip');
    elseif strcmp(type,'ipl')
        fo = interp1(isc.freq,isc.ipl,f,'pchip');
    else
        error('Unrecognized calibration type. Must be a string: spl, fpl, rpl, or ipl.')
    end
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
else % the stimulus is broadband
    error('Calibration correction of broadband stimuli has not been implemented yet.')
end

