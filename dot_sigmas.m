function [ output ] = dot_sigmas( varargin )
%dot_sigmas: returns available sigma parameters for dot fitting.  
%   If called with no arguments, returns list of all available sigmas.  If
%   called with an integer value, returns the vector [sigmaxy, sigmaz]
%   corresponding to that entry in the list

sigmalist = {'Gilad (3.12 / 5.78)', 'Dan (2.24 /1.20)'};
sigmas = [3.125, 5.78; 2.24, 1.20];

if nargin == 0
    output = sigmalist;
elseif nargin == 1
    output = sigmas(varargin{1},:);
end


end

