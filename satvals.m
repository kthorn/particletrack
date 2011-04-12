function [minI maxI] = satvals (image, satfxn)
    %returns values for scaling an image to give satfxn saturated pixels
    image = double(image);
    bins = min(image(:)):max(image(:));
    Idist = hist(image(:),bins);
    Icum = cumsum(Idist);
    Icum = Icum ./ sum(Idist);
    minI = find(Icum < satfxn, 1, 'last' );
    maxI = find(Icum > 1-satfxn, 1 );
    if isempty(minI)
        minI = 1;
    end
    if isempty(maxI)
        maxI = numel(bins);
    end
    minI = bins(minI);
    maxI = bins(maxI);