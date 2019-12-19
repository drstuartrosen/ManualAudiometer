function dB = TimsMAP(f)
%
%   TimsMAP - a MAP which is a frequency dependent weighting of Killion (at
%   low frequencies) and Lee (at higher frequencies). The weighting is done
%   through a logistic function on a log frequency scale with a cutoff
%   frequency = 2 kHz, and in which the transition region is ~ 2 oct wide
%
%   Stuart Rosen June 2018
%
Lfrqs = [125 250 500 750 1000 1500 2000 3000 4000 6000 8000 10000 11200 12500 14000 15000 16000 17000 18000 19000 20000];
L = [34.83 25.4 15.17 11.67 10.52 14.96 17.22 15.24 12.67 14.25 16.35 20.44 22.99 27.16 33.43 40.69 48 64.7 83.45 93.81 93.07];
Kfrqs = [125 250 500 1000 2000 3000 4000 6000 8000];
K=[30 19 12 9 15 15.5 13 13 14];
frqs=MyLogSpace(125, 20000, 50);
newK = interp1(log10(Kfrqs), K, log10(frqs), 'spline',K(end));
newL = interp1(log10(Lfrqs), L, log10(frqs), 'spline');
%% checks
% semilogx(Kfrqs,K,'bo')
% hold on
% semilogx(frqs,newK)
% grid on
% hold off

%% weight between 
mu=log10(2000);
s=.1;
w=cdf('Logistic',log10(frqs),mu,s);
TimsMAP=(1-w).*newK + w.*newL;
dB = interp1( log10(frqs), TimsMAP, log10(f), 'spline');
