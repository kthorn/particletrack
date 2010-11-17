%Instructions: replace data_to_analyze with name of variable to analyze
%save and hit F5 to run (or extract_flagged at command line)

%parameters of flagged dots are accumulated into results
%when done with one type of cell, rename results and fxn_2dots and it will start from
%scratch on next run.

temp_anal = data_to_analyze;

if ~exist('results')
    j=1;
end

for n=1:size(temp_anal,2)
    if any(strcmp(temp_anal(n).flags, 'disappearing'))
        result = temp_anal(n).modelI;
        results(j,:)=result;
        %start and length of disappearence
        start = temp_anal(n).modelI(2);
        tlen = temp_anal(n).modelI(3);
        fxn_2dots(j) = numel(find(temp_anal(n).ndots(start:start+tlen) == 2))/(tlen+1);
        j=j+1;
    end
    
end


