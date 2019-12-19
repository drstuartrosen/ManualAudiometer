function y = MyLogSpace(a,b,n) 

% y = MyLogSpace(a,b,n) generates n points between a and b.
% y = logspace(a,b,n) generates n points between decades 10^a and 10^b.

if nargin<3
    n=10;
end
if nargin<2
    error('MyLogSpace() needs at least two arguments');
end

y=logspace(log10(a), log10(b),n);

