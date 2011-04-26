function MMstructure = MMstruct (directory)
%
%MMstruct - returns the structure of the Micro-Manager data set in
%directory

%regular expression for parsing filenames
RE = 'img_(\d+)_(.+)_(\d+).tif';
prefix = 'img';

files=dir(fullfile(directory,'*.tif'));
max_time=0;
max_z=0;
nwaves=1;
wavelengths={};
for n=1:max(size(files))
    if ~files(n).isdir
        fileparts = regexp(files(n).name, RE, 'tokens');
        fileparts = fileparts{1};
        max_time=max(max_time,str2double(fileparts{1}));
        z = regexp(fileparts{3}, '\.', 'split');
        max_z=max(max_z,str2double(z{1}));
        if isempty(wavelengths)
            wavelengths{nwaves}=fileparts{2};
        else
            if ~any(strcmpi(wavelengths,fileparts{2}))
                nwaves=nwaves+1;
                wavelengths{nwaves}=fileparts{2};
            end
        end
    end
end
testim=imread(fullfile(directory,[prefix,'_000000000_',wavelengths{1},'_000.tif']));

MMstructure.imsize = size(testim);
MMstructure.ntimepoints = max_time;
MMstructure.nz = max_z;
MMstructure.nwavelengths = nwaves;
MMstructure.wavelengthlist = wavelengths;
