function imstack = MMparse(directory, varargin)

%varargin{1} = number of time points to read; [] to read all
%varargin{2} = wavelength(s) to read - string array of valid wavelength names

files=dir(fullfile(directory,'*.tif'));
max_time=0;
max_z=0;
nwaves=1;
wavelengths={};
for n=1:max(size(files))
    if ~files(n).isdir
        fileparts = regexp(files(n).name, '_', 'split');
        prefix = fileparts{1};
        max_time=max(max_time,str2double(fileparts{2}));
        z = regexp(fileparts{4}, '\.', 'split');
        max_z=max(max_z,str2double(z{1}));
        if isempty(wavelengths)
            wavelengths{nwaves}=fileparts{3};
        else
            if ~any(strcmpi(wavelengths,fileparts{3}))
                nwaves=nwaves+1;
                wavelengths{nwaves}=fileparts{3};
            end
        end
    end
end
if nargin > 1
    if ~isempty(varargin{1})
        max_time = varargin{1} - 1;
    end
end
if nargin > 2
    wavelengths = varargin{2};
    nwaves = numel(wavelengths);
end
testim=imread(fullfile(directory,[prefix,'_000000000_',wavelengths{1},'_000.tif']));
imstack=zeros([size(testim) max_z+1 max_time+1 nwaves],'uint16');
for z=0:max_z
    for t=0:max_time
        for w=1:nwaves
            imstack(:,:,z+1,t+1,w)=imread(fullfile(directory,[prefix,'_',sprintf('%09d',t),'_',wavelengths{w},'_',sprintf('%03d',z),'.tif']));
        end
    end
end