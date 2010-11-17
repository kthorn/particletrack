function fxn_2dots = splitting_info(data_struct)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

q=1;
for n=1:size(data_struct,2)
    if any(strcmp(data_struct(n).flags, 'disappearing'))
        %start and length of disappearence
        start = data_struct(n).modelI(2);
        tlen = data_struct(n).modelI(3);
        fxn_2dots(q) = numel(find(data_struct(n).ndots(start:start+tlen) == 2))/(tlen+1);
        q=q+1;
    end
end
end
