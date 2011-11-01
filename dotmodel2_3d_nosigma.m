function F = dotmodel2_3d_nosigma(x,xdata)
%x(1) = constant background
%nucleus params
%x(2:4) = centroid x, y, z coordinates
%x(5) = sigma x
%x(6) = sigma y
%x(7) = sigma z
%x(8) = covariance
%x(9) = peak height
%dot params
%x(10:12) = dot centroid x, y, z coordinates
%x(13) = peak height
%dot 2 params
%x(14:16) = dot centroid x, y, z coordinates
%x(17) = peak height of 2nd dot



sigmaxy = 3.125; % 2*(1.25^2)
sigmaz = 5.78; %2*(1.7^2)
%for 60x oil:
%sigmaxy = 2.24;
%sigmaz = 1.20;


X=xdata(:,1);
Y=xdata(:,2);
Z=xdata(:,3);

% nucleus gaussian kernel
nuckern = (X-x(2)).^2 ./ (2*x(5)^2) + (Y-x(3)).^2 ./ (2*x(6)^2) + ...
          (X-x(2)).*(Y-x(3)).*x(8)  + (Z-x(4)).^2 ./ (2*x(7)^2);
dotkern  = (((X-x(10)).^2 + (Y-x(11)).^2) ./ sigmaxy + (Z-x(12)).^2 ./sigmaz);
dotkern2 = (((X-x(14)).^2 + (Y-x(15)).^2) ./ sigmaxy + (Z-x(16)).^2 ./ sigmaz);
nuc = x(9) * exp (-nuckern);
dot = x(13) * exp (-dotkern);
dot2 = x(17) * exp (-dotkern2);
F = x(1) + nuc + dot + dot2;