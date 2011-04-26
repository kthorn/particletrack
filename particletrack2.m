function varargout = particletrack2(varargin)
% PARTICLETRACK2 M-file for particletrack.fig
%      PARTICLETRACK2, by itself, creates a new PARTICLETRACK2 or raises the existing
%      singleton*.
%
%      H = PARTICLETRACK2 returns the handle to a new PARTICLETRACK2 or the handle to
%      the existing singleton*.
%
%      PARTICLETRACK2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PARTICLETRACK2.M with the given input arguments.
%
%      PARTICLETRACK2('Property','Value',...) creates a new PARTICLETRACK2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before particletrack2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to particletrack2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help particletrack2

% Last Modified by GUIDE v2.5 29-Mar-2011 14:55:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @particletrack2_OpeningFcn, ...
    'gui_OutputFcn',  @particletrack2_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before particletrack2 is made visible.
function particletrack2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to particletrack2 (see VARARGIN)

% Choose default command line output for particletrack2
handles.output = hObject;
set(handles.remove_dots,'Enable','off');
set(handles.queue,'Enable','off');
set(handles.analyze,'Enable','off');
set(handles.wavelength_list,'Enable','off');
set(handles.model_list,'Enable','off');
set(handles.master_button,'Enable','off');
set(handles.find_dots,'Enable','off');
set(handles.add_dots,'Enable','off');

%get models

handles.models = models;

set(handles.model_list,'String',handles.models.modelnames);

%default parameters
handles.min_dot_dist = 7; %dots closer than this belong to same cell

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes particletrack2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);



function dir_to_read_Callback(hObject, eventdata, handles)
% hObject    handle to dir_to_read (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get structure of data set

filedir = get(handles.dir_to_read,'String');
MMstructure = MMstruct(filedir);
set(handles.wavelength_list,'String',MMstructure.wavelengthlist);

%enable selection menus
set(handles.wavelength_list,'Enable','on');
set(handles.model_list,'Enable','on');
set(handles.master_button,'Enable','on');

%create new dataset descriptor for input to fitter
handles.data.inputdata = fitDataDescriptor (filedir, MMstructure.wavelengthlist);

update_wavelength_ui(handles);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function dir_to_read_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dir_to_read (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in analyze.
function analyze_Callback(hObject, eventdata, handles)
% hObject    handle to analyze (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

nqueued = size(handles.data.queued,2);
for n = 1:nqueued
    set(handles.status,'String',['Analyzing ', sprintf('%d',n), ' of ', sprintf('%d',nqueued)]);
    drawnow expose update
    model = model_fitter(handles.data.queued(n).input);
    save(fullfile(handles.data.queued(n).input.directory,'analysis.mat'),'model');
end
set(handles.status,'String','Done Analyzing');

guidata(hObject, handles);


% --- Executes on button press in queue.
function queue_Callback(hObject, eventdata, handles)
% hObject    handle to queue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles.data, 'queued')
    nqueued = size(handles.data.queued,2);
else
    nqueued = 0;
end
handles.data.queued(nqueued+1).input = handles.data.inputdata;

set(handles.status,'String','Dataset queued');

set(handles.analyze,'Enable','on');
guidata(hObject, handles);

% --- Executes on button press in find_dots.
function find_dots_Callback(hObject, eventdata, handles)
% hObject    handle to find_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get image to search in
master_wave = handles.data.inputdata.master;
wavelength_list = handles.data.inputdata.getChannelNames;
wavenum = strcmp(master_wave, wavelength_list);
master_image = handles.data.images(:,:,:,wavenum);

thresh = str2double(get(handles.threshold,'String'));

%filter image
testfilt = sharpen_image (master_image);

%find peaks
s=regionprops(testfilt>thresh, master_image, 'WeightedCentroid');
startcoords=zeros([size(s,1) 3]);
for n=1:size(s,1)
    startcoords(n,:)=round(s(n).WeightedCentroid);
end

%remove dots too close to edges of image or to other dots
d=squareform(pdist(startcoords));
[r,c]=find(d<handles.min_dot_dist & d>0);
pair_idx = r<c;
c=c(pair_idx);  %upper halves of close dots
startcoords(c,:)=[]; %remove paired dots

boxsize = str2double(get(handles.boxsize,'String'));
XYbound = boxsize*2;
Zbound = 2;
imsize = size(master_image);
handles.data.inputdata.boxsize = boxsize;
badcoords = any(startcoords(:,1:2)' < XYbound) | startcoords(:,1)' > imsize(:,1)-XYbound | startcoords(:,2)' > imsize(:,2)-XYbound | ...
            startcoords(:,3)' < Zbound | startcoords(:,3)' > imsize(:,3)-Zbound;
startcoords(badcoords',:)=[];

%save coordinates
handles.data.inputdata.coordinates = startcoords;

update_image(max(handles.data.images,[],3), handles.data.inputdata);
set(handles.status,'String',['Found ', sprintf('%d', size(startcoords,1)), ' Dots']);
set(handles.remove_dots,'Enable','on');
set(handles.queue,'Enable','on');
set(handles.add_dots,'Enable','on');

guidata(hObject, handles);


% --- Executes on button press in add_dots.
function add_dots_Callback(hObject, eventdata, handles)
% hObject    handle to add_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figure(1)
[x,y]=ginput(1);
[~, z]=max(handles.data.images(round(y),round(x),:,1));
handles.data.inputdata.coordinates = [handles.data.inputdata.coordinates;[x y z]];

update_image(max(handles.data.images,[],3),handles.data.inputdata);

set(handles.remove_dots,'Enable','on');
set(handles.queue,'Enable','on');

guidata(hObject, handles);


% --- Executes on button press in remove_dots.
function remove_dots_Callback(hObject, eventdata, handles)
% hObject    handle to remove_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figure(1)
[x,y]=ginput(1);
dist=zeros([1 size(handles.data.inputdata.coordinates,1)]);
for n=1:size(handles.data.inputdata.coordinates,1)
    dist(n) = (handles.data.inputdata.coordinates(n,1)-x).^2 + (handles.data.inputdata.coordinates(n,2)-y).^2;
end
[junk, point_to_remove]=min(dist);
handles.data.inputdata.coordinates(point_to_remove,:)=[];
update_image(max(handles.data.images,[],3),handles.data.inputdata);

guidata(hObject, handles);


% --- Executes on button press in load.
function load_Callback(hObject, eventdata, handles)
% hObject    handle to load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.status,'String','Loading Images');
drawnow expose update
wavelengthlist = get(handles.wavelength_list,'String');
%wavelength = wavelengthlist{get(handles.wavelength_list,'Value')};

%load stack
images = MMparse(get(handles.dir_to_read,'String'),1,wavelengthlist); %load first time point, all wavelengths
%currently we only handle two channels properly

c1 = squeeze(images(:,:,:,:,1));
c2 = squeeze(images(:,:,:,:,2));
c1 = c1 - median(c1(:));
c2 = c2 - median(c2(:));

%background subtract
handles.data.images(:,:,:,1)=c1;
handles.data.images(:,:,:,2)=c2;
dims = size(handles.data.images);
set(handles.status,'String',['Loaded ', sprintf('%d', prod(dims(3:4))), ' Images']);

set(handles.queue,'Enable','off');
set(handles.find_dots,'Enable','on');
set(handles.add_dots,'Enable','on');

update_image(max(handles.data.images,[],3), handles.data.inputdata);
guidata(hObject, handles);


% --- Executes on selection change in wavelength_list.
function wavelength_list_Callback(hObject, eventdata, handles)
% hObject    handle to wavelength_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

update_wavelength_ui(handles);
guidata(hObject, handles);


% --- Executes on selection change in model_list.
function model_list_Callback(hObject, eventdata, handles)
% hObject    handle to model_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%update structure to assign model to wavelength
modellist = get(handles.model_list,'String');
chosen_model = modellist{get(handles.model_list,'Value')};

wavelengthlist = get(handles.wavelength_list,'String');
wavelength = wavelengthlist{get(handles.wavelength_list,'Value')};

%update channel
handles.data.inputdata.setModelName(wavelength, chosen_model);
guidata(hObject, handles);


% --- Executes on button press in master_button.
function master_button_Callback(hObject, eventdata, handles)
% hObject    handle to master_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of master_button

wavelengthlist = get(handles.wavelength_list,'String');
wavelength = wavelengthlist{get(handles.wavelength_list,'Value')};
if get(hObject,'Value') == 1
    %update channel
    handles.data.inputdata.master = wavelength;
else
    warning ('pt:uiwarn','You cannot unset master state; please set another wavelength to master instead');
    set(hObject,'Value',1);
end
guidata(hObject, handles);


function boxsize_Callback(hObject, eventdata, handles)
% hObject    handle to boxsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of boxsize as text
%        str2double(get(hObject,'String')) returns contents of boxsize as a double
handles.data.inputdata.boxsize = str2double(get(hObject,'String'));
if isfield(handles.data, 'images')
    update_image(max(handles.data.images,[],3), handles.data.inputdata);
end
guidata(hObject, handles);

%% utility functions, non-callbacks

function update_image(image, inputdata)

%image should be 2 or 3d; if 3d, 3rd axis is assumed to be wavelength
figure(1)
clf
image = squeeze(image);
satfxn = 0.0002;
if ndims(image) == 3
    %generate RGB image
    RGB = zeros([size(image,1), size(image,2), 3]);
    [minI, maxI] = satvals(image(:,:,1), satfxn);
    tempim = double(image(:,:,1) - minI);
    tempim = tempim./maxI;
    tempim = max(tempim,0);
    tempim = min(tempim,1);
    RGB(:,:,2)=tempim;
    
    [minI, maxI] = satvals(image(:,:,2), satfxn);
    tempim = double(image(:,:,2) - minI);
    tempim = tempim./maxI;
    tempim = max(tempim,0);
    tempim = min(tempim,1);
    RGB(:,:,1)=tempim;
else    
    [minI, maxI] = satvals(image, satfxn);
    tempim = double(image - minI);
    tempim = tempim./maxI;
    tempim = max(tempim,0);
    tempim = min(tempim,1);
    RGB = tempim;
end

%calculate cumulative histogram and saturate top and bottom satfxn

imshow(RGB);
hold on
len = inputdata.boxsize;
for n=1:size(inputdata.coordinates,1)
    xcen = inputdata.coordinates(n,1);
    ycen = inputdata.coordinates(n,2);
    %circles centered on dot startcoordinates
    plot(xcen,ycen,'wo');
    %boxes around search area
    rectangle('Position', [xcen-len, ycen-len, 2*len, 2*len], 'EdgeColor',[0.6 0.6 0.6], 'LineStyle', ':');
end


function update_wavelength_ui (handles)

wavelengthlist = get(handles.wavelength_list,'String');
wavelength = wavelengthlist{get(handles.wavelength_list,'Value')};
%set master if appropriate
if handles.data.inputdata.isMaster (wavelength)
    set(handles.master_button, 'Value', 1);
else
    set(handles.master_button, 'Value', 0);
end

model = handles.data.inputdata.getModelName(wavelength);

modellist = get(handles.model_list,'String');
for n = 1:numel(modellist)
    if strcmp(model, modellist{n})
        set(handles.model_list,'Value',n);
    end
end

%% Unusued callbacks


% --- Executes during object creation, after setting all properties.
function model_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to model_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function wavelength_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wavelength_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
function threshold_Callback(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold as text
%        str2double(get(hObject,'String')) returns contents of threshold as a double


% --- Executes during object creation, after setting all properties.
function threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Outputs from this function are returned to the command line.
function varargout = particletrack2_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function boxsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to boxsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
