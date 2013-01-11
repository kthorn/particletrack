function  m  = intmedian( x )
%Replacement for median that handles integer values
%   Detailed explanation goes here

if isfloat(x)
    m = median(x);
elseif isinteger(x)
    c = class(x);
    m = median(single(x));
    m = cast(m, c);
end

end

