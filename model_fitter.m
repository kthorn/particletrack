function  outputmodel = model_fitter( inputdata )
%model_fitter - takes inputdata (a fitDataDescriptor) and passes it to the
% appropriate fitting code to determine the model (a fitModel).

clist = inputdata.getChannelNames;
for n=1:numel(clist)
    nn=1;
    model = inputdata.getModel(clist{n});
    %don't include unmodeled channels
    if ~strcmp(model, 'None');
        wavelengthlist{nn} = clist{n};
        nn = nn + 1;
    end
end

ims = MMparse(inputdata.directory,[],wavelengthlist);
master_channel = find(strcmp(wavelengthlist, inputdata.master));

ntime = size(ims,4);
ncells = size(inputdata.coordinates,1);

%generate a new output model and initialize it.
outputmodel = fitModel(inputdata, ntime);

for cell = 1:size(inputdata.coordinates,1)
    coords = squeeze(inputdata.coordinate(cell, :));
    
    for time = 1:ntime
        %cut out subimage for fitting
        subimage = ims(coords(1)-boxsize:coords(1)+boxsize,coords(2)-boxsize:coords(2)+boxsize,:,:);
        
        %fit all channels
        for chan = 1:numel(wavelengthlist)
            outputmodel.channel(chan).models(cell, time).fit(subimage(:,:,:,chan));
        end
        
        %get updated coordinates for next time point from master channel
        coords = outputmodel.channel(master_channel).models(cell, time).finalCoords;
    end
end


end

