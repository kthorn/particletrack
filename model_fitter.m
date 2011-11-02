function  outputmodel = model_fitter( inputdata )
%model_fitter - takes inputdata (a fitDataDescriptor) and passes it to the
% appropriate fitting code to determine the model (a fitModel).

clist = inputdata.getChannelNames;
nn=1;
for n=1:numel(clist)
    model = inputdata.getModelName(clist{n});
    %don't include unmodeled channels
    if ~strcmp(model, 'None');
        wavelengthlist{nn} = clist{n};
        nn = nn + 1;
    end
end

%ims = MMparse(inputdata.directory,2,wavelengthlist);
ims = MMparse(inputdata.directory,[],wavelengthlist);
master_channel = find(strcmp(wavelengthlist, inputdata.master));

imsize = size(ims);
ntime = imsize(4);
ncells = size(inputdata.coordinates,1);

%generate a new output model and initialize it.
outputmodel = fitModel(inputdata, ntime);
boxsize = inputdata.boxsize;

disp('starting fitting')

for cell = 1:size(inputdata.coordinates,1)
    coords = squeeze(inputdata.coordinates(cell, :));
    tic
    for time = 1:ntime
        %cut out subimage for fitting
        if any(isnan(coords(1:2)))
            %lost track of cell, abandon fit
            break
        end
        %check to see if subimage falls outside of image area
        if any(coords(1:2)-boxsize < 1) || any(coords(1:2)+boxsize > imsize(1:2))
            %cell is too close to edge, abandon fit
            break
        end
        subimage = squeeze(ims(coords(2)-boxsize:coords(2)+boxsize,coords(1)-boxsize:coords(1)+boxsize,:,time,:));
        %         figure(2)
        %         imshow(max(subimage,[],3),[]);
        %fit all channels
        for chan = 1:numel(wavelengthlist)
            outputmodel.channel(chan).models(cell, time).fit(subimage(:,:,:,chan), inputdata.sigmas);
            outputmodel.channel(chan).models(cell, time).initcoords = coords;
            outputmodel.channel(chan).models(cell, time).boxsize = boxsize;
            %             figure(3)
            %             imshow(max(outputmodel.channel(chan).models(cell, time).showModel,[],3),[])
            %             pause
        end
        
        
        %get updated coordinates for next time point from master channel
        coords = round(outputmodel.channel(master_channel).models(cell, time).finalCoords('full'));
    end
    disp(['Cell ', sprintf('%d', cell), ' done'])
    toc
end


end

