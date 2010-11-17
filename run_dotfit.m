temp_anal = rewt1_12_8_09_anal;

for n=1:size(temp_anal,2)
    %    if any(strcmp(temp_anal(n).flags, 'disappearing'))
    result = fit_disappearance(temp_anal(n).dotI');
    figure(1)
    clf
    plot(temp_anal(n).dotI,'b')
    hold on
    plot(model_results(result),'r')
    button = questdlg('Keep dot?')
    if strcmp(button, 'Yes')
        results(j,:)=result;
        j=j+1;
    end
    if strcmp(button, 'Cancel')
        break
    end
    %    end
end

