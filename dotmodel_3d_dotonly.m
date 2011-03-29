function F = dotmodel_3d_dotonly(x,xdata)
%x(1) = constant background
%nucleus params
%x(2:4) = dot x, y, z coordinates
%x(5) = peak height

sigmaxy = 3.125; %2*(1.25^2)
sigmaz = 5.78; %2*(1.7^2)

X=xdata(:,1);
Y=xdata(:,2);
Z=xdata(:,3);

% nucleus gaussian kernel
dotkern = (((X-x(2)).^2 + (Y-x(3)).^2) ./ sigmaxy + (Z-x(4)).^2 ./sigmaz);

dot = x(5) * exp (-dotkern);
F = x(1) + dot;