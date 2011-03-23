function imfilt = sharpen_image (im)
%applies a negative LoG filter to sharpen image for peak finding
%filter radius is set to optimum for finding diffraction limited dots on
%spinning disk at 60x.

%filter function
h=-fspecial('log',5,1);

%sharpen image to find dots
imfilt = zeros(size(im));
for z=1:size(im,3)
    imfilt(:,:,z)=imfilter(im(:,:,z),h,'symmetric');
end