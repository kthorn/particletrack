function updatedresult = update_coords_nosigma (fitresult, initX, initY, length)
length=length+1;
Yoff=initY-length;
Xoff=initX-length;
if (size(fitresult,2) == 13)
    %1 dot model
    updatedresult=fitresult;
    updatedresult(2)=updatedresult(2)+Yoff;
    updatedresult(3)=updatedresult(3)+Xoff;
    updatedresult(10)=updatedresult(10)+Yoff;
    updatedresult(11)=updatedresult(11)+Xoff;
elseif (size(fitresult,2) == 17 || size(fitresult,2) == 16)
    %2 dot model
    updatedresult=fitresult;
    updatedresult(2)=updatedresult(2)+Yoff;
    updatedresult(3)=updatedresult(3)+Xoff;
    updatedresult(10)=updatedresult(10)+Yoff;
    updatedresult(11)=updatedresult(11)+Xoff;    
    updatedresult(14)=updatedresult(14)+Yoff;
    updatedresult(15)=updatedresult(15)+Xoff;
else
    error('Result vector is wrong length');
end