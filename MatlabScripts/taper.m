function s=taper(wave, rise, fall, SampFreq, type)
%
% s=taper(wave, rise, fall, SampFreq, type)
%
% taper a given waveform
% null input wave leads to null output
% Put rises and falls onto a waveform 'wave'
% rise and fall times are specified independently in ms
% type - 'linear' or 'cosine' = raised cosine
%     DEFAULT: raised cosine

%
% One-half cycle of a raised cosine is used.                                
% In this implementation, the start of the rise (e.g.          
% wave_start) is set to 0 (explicitly) while its end
% (e.g. wave_start[rise-1]) is left at its original amplitude.
% Intermediate values are scaled in accordance with the raised
% cosine. For rise times of 2 points or less, the original
% waveform is left unchanged.                                
% The raised cosine routine is based on taper.c from aud_ml7
%
% Stuart Rosen    stuart@phon.ucl.ac.uk
% Vs 2.0 -- January 2003
% incorporate linear shape into main taper function
% slight change to cosine taper (rise/fall is not 0 or 1 for 1 more sample point)
% in order to make linear and cosine rises and falls exactly equal in length

if (isempty(wave))
   s = [];
   return
end

if nargin<4
    error('Insufficient number of arguements. Type "help taper" for more information.');
elseif nargin<5
    type='cosine';
end

% calculate rise and fall times in numbers of samples
rise = samplify(rise, SampFreq);
fall = samplify(fall, SampFreq);

if strcmp(type,'cosine')
    s = wave;
	if rise>2
        pi_over_rf = pi/rise;
        for n=1:rise 	% needn't do n=0 because k=1 there
            k = 0.5 + 0.5 * cos(n * pi_over_rf);
            s(1+rise-n) = k * s(1+rise-n);
        end
        % ensure that wave goes to zero at beginning of rise
        s(1)=0;
	end
	
	if fall>2
        pi_over_rf = pi/fall;
        finish = length(s);
        for n=1:fall 	% needn't do n=0 because k=1 there
            k = 0.5 + 0.5 * cos(n * pi_over_rf);
            s(finish+(n-(fall))) = k * s(finish+(n-(fall)));
         end
        % ensure that wave goes to zero at end of fall
        s(length(s))=0;
	end
elseif strcmp(type,'linear')
	% construct the envelope
	last = length(wave);
	z = ones(size(wave));
	
	inc = 1.0/rise;
	for i=1:rise
       z(i)= (i-1) * inc;
	end
	
	inc = 1.0/fall;
	for i=1:fall
       z(last-(i-1))= (i-1) * inc;
	end
	
	s = z.*wave;
else
    error('rise/fall type must be "linear" or "cosine". Type "help taper" for more information.');
end

function samples = samplify(duration, SampFreq)

samples = floor(SampFreq*(duration/1000));
