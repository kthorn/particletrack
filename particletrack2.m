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

% Last Modified by GUIDE v2.5 23-Mar-2011 11:54:20

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

%get models

handles.models = models;

set(handles.model_list,'String',handles.models.modelnames);

%default parameters
handles.len = 9; %size of box in XY to fit around each dot
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
    ims = MMparse(handles.data.queued(n).dir,[],{handles.data.queued(n).wavelength});
    model = yeast_dot_track(ims, handles.data.queued(n).model, handles.len);
    save(fullfile(handles.data.queued(n).dir,'analysis.mat'),'model','ims');
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
handles.data.queued(nqueued+1).model = handles.data.model;
handles.data.queued(nqueued+1).dir = get(handles.dir_to_read,'String');

wavelengthlist = get(handles.wavelength_list,'String');
wavelength = wavelengthlist{get(handles.wavelength_list,'Value')};
handles.data.queued(nqueued+1).wavelength = wavelength;

set(handles.status,'String','Dataset queued');

set(handles.analyze,'Enable','on');
guidata(hObject, handles);

% --- Executes on button press in find_dots.
function find_dots_Callback(hObject, eventdata, handles)
% hObject    handle to find_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%parameters
h=fspecial('log',5,1);
%remove points closer to edge of image stack than this
XYbound = 20;
Zbound = 4;

%image
t1=handles.data.images;
thresh = str2double(get(handles.threshold,'String'));

%initial parameters for fit
init_template = double([min(t1(:)),  handles.len+1, handles.len+1,  5,  4,  4,  3,  0, thresh*2, handles.len+1, handles.len+1,  5, thresh*3, handles.len+1, handles.len+1, 5 thresh*3]);

%filter image
testfilt=zeros(size(t1));
for z=1:size(t1,3)
    testfilt(:,:,z)=imfilter(t1(:,:,z),-h,'symmetric');
end

%find peaks
s=regionprops(testfilt>thresh,t1,'WeightedCentroid');
startcoords=zeros([size(s,1) 3]);
for n=1:size(s,1)
    startcoords(n,:)=round(s(n).WeightedCentroid);
end

%remove dots too close to edges of image or to other dots
d=squareform(pdist(startcoords));
[r,c]=find(d<handles.min_dot_dist & d>0);
pair_idx = find (r<c);
r=r(pair_idx);
c=c(pair_idx);  %upper halves of close dots

startcoords(c,:)=[]; %remove paired dots

XYbound=handles.len*2;
badcoords = any(startcoords(:,1:2)' <XYbound) | startcoords(:,1)'>512-XYbound | startcoords(:,2)'>512-XYbound;
startcoords(badcoords',:)=[];
nmodel=1;
if isfield(handles.data,'model')
    handles.data = rmfield(handles.data, 'model');
end
for n=1:size(startcoords,1);
    handles.data.model(nmodel).initparams = init_template;
    handles.data.model(nmodel).initparams(2) = startcoords(n,2);
    handles.data.model(nmodel).initparams(3) = startcoords(n,1);
    handles.data.model(nmodel).initparams(4) = startcoords(n,3);
    handles.data.model(nmodel).initparams(10) = startcoords(n,2);
    handles.data.model(nmodel).initparams(11) = startcoords(n,1);
    handles.data.model(nmodel).initparams(12) = startcoords(n,3);
    handles.data.model(nmodel).initparams(14) = startcoords(n,2);
    handles.data.model(nmodel).initparams(15) = startcoords(n,1);
    handles.data.model(nmodel).initparams(16) = startcoords(n,3);
    nmodel=nmodel+1;
end

update_image(handles.axes, max(t1,[],3), handles.data.model);
set(handles.status,'String',['Found ', sprintf('%d', size(handles.data.model,2)), ' Dots']);
set(handles.remove_dots,'Enable','on');
set(handles.queue,'Enable','on');
handles.data.time=1;

guidata(hObject, handles);


% --- Executes on button press in add_dots.
function add_dots_Callback(hObject, eventdata, handles)
% hObject    handle to add_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[x,y]=ginput(1);
[~, z]=max(handles.data.images(round(y),round(x),:,1));
nmodels=size(handles.data.model,2);
handles.data.model(nmodels+1).initparams = handles.init_template;
handles.data.model(nmodels+1).initparams(2) = y;
handles.data.model(nmodels+1).initparams(3) = x;
handles.data.model(nmodels+1).initparams(4) = z;
handles.data.model(nmodels+1).initparams(10) = y;
handles.data.model(nmodels+1).initparams(11) = x;
handles.data.model(nmodels+1).initparams(12) = z;
handles.data.model(nmodels+1).initparams(14) = y;
handles.data.model(nmodels+1).initparams(15) = x;
handles.data.model(nmodels+1).initparams(16) = z;

update_image(handles.axes,max(handles.data.images(:,:,:,1),[],3),handles.data.model);

set(handles.remove_dots,'Enable','on');
set(handles.queue,'Enable','on');

guidata(hObject, handles);


% --- Executes on button press in remove_dots.
function remove_dots_Callback(hObject, eventdata, handles)
% hObject    handle to remove_dots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[x,y]=ginput(1);
dist=zeros([1 size(handles.data.model,2)]);
for n=1:size(handles.data.model,2)
    dist(n) = (handles.data.model(n).initparams(11)-x).^2 + (handles.data.model(n).initparams(10)-y).^2;
end
[junk, point_to_remove]=min(dist);
handles.data.model(point_to_remove)=[];
update_image(handles.axes,max(handles.data.images(:,:,:,1),[],3),handles.data.model);

guidata(hObject, handles);

%% Load Button callback
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

guidata(hObject, handles);

%% Wavelength list callback
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
    handles.data.inputdata.setMaster(wavelength);
else
    warning ('pt:uiwarn','You cannot unset master state; please set another wavelength to master instead');
    set(hObject,'Value',1);
end
guidata(hObject, handles);

%% utility functions, non-callbacks

function update_image(target_axis,image,model)
cla(target_axis)
imshow(image,[],'Parent',target_axis);
hold on
for n=1:size(model,2)
    plot(model(n).initparams(11),model(n).initparams(10),'ro');
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
