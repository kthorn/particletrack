function F = dotmodel_3d_2dotonly(x, xdata, sigmas)
%x(1) = constant background
%nucleus params
%x(2:4) = dot x, y, z coordinates
%x(5) = peak height
%x(6:8) = 2nd dot x, y, z coordinates
%x(9) = 2nd peak height

%sigmaxy = 3.125; %2*(1.25^2)
%sigmaz = 5.78; %2*(1.7^2)
sigmaxy = sigmas(1);
sigmaz = sigmas(2);

X=xdata(:,1);
Y=xdata(:,2);
Z=xdata(:,3);

% nucleus gaussian kernel
dotkern1 = (((X-x(2)).^2 + (Y-x(3)).^2) ./ sigmaxy + (Z-x(4)).^2 ./sigmaz);
dotkern2 = (((X-x(6)).^2 + (Y-x(7)).^2) ./ sigmaxy + (Z-x(8)).^2 ./sigmaz);
dot1 = x(5) * exp (-dotkern1);
dot2 = x(9) * exp (-dotkern2);
F = x(1) + dot1 + dot2;