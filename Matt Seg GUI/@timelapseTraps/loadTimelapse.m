function loadTimelapse(cTimelapse,searchString,magnfication,image_rotation,trapsPresent,timepointsToLoad,imScale)

folder=cTimelapse.timelapseDir;
tempdir=dir(folder);
nfiles=0;
names=cell(1);
% ran into a bug with some .img files that should have been hidden. Ignore
% any file with . at the beginning
for i=1:length(tempdir)
    if ~strcmp(tempdir(i).name(1),'.')
        names{i}=tempdir(i).name;
    else
        names{i}='';
    end
end

cTimelapse.channelNames=searchString;

files=sort(names);
%% Read images into timelapse class
% Timelapse is a seletion of images from a file. These images must be
% loaded in the correct order from low to high numbers to ensure that the
% cell tracking performs correctly, and they must be rotated to ensure the
% trap correctly aligns with the images

timepoint_index=0;
folder=[folder '/']

newfiles=cell(1);

% definition of basic timepoint structure
cTimepointTemplate = struct('filename',[],'trapLocations',[],...
                            'trapInfo',[],'trapMaxCell',[],'trapMaxCellUTP',[]);

cTimelapse.cTimepoint = cTimepointTemplate;
                        
largestTimepoint = 0;
for ss=1:length(searchString)
    timepoint_index=0;
    for n = 1:length(files);
        if isempty(strfind(files{n},'tif'))|| isempty(strfind(files{n},'png')) || isempty(strfind(files{n},'TIF'))
            if length(strfind(files{n},searchString{ss}))
                cTimelapse.cTimepoint(timepoint_index+1).filename{ss}=[folder files{n}];
                cTimelapse.cTimepoint(timepoint_index+1).trapLocations=[];
                timepoint_index=timepoint_index+1;
            end
        end
    end
    largestTimepoint = max([timepoint_index;largestTimepoint]);
end

cTimelapse.timepointsToProcess = 1:largestTimepoint;

if nargin>=6 && ~isempty(timepointsToLoad)
    if max(timepointsToLoad)>length(cTimelapse.cTimepoint)
        timepointsToLoad=timepointsToLoad(timepointsToLoad<=length(cTimelapse.cTimepoint));
    end
    cTimelapse.cTimepoint=cTimelapse.cTimepoint(timepointsToLoad);
end

image=imread(cTimelapse.cTimepoint(1).filename{1});
cTimelapse.imSize=size(image);
if nargin<3 || isempty(magnfication)
    h=figure;imshow(image,[]);
    prompt = {'Enter the magnification of the objective used'};
    dlg_title = 'magnification';
    num_lines = 1;
    def = {'60'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cTimelapse.magnification=str2num(answer{1});
    close(h);
else
    cTimelapse.magnification=magnfication;
end

%
if nargin<5 || isempty(trapsPresent)
    prompt = {'Are traps present in this Timelapse?'};
    dlg_title = 'TrapsPresent';
    num_lines = 1;
    def = {'Yes'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if ~strcmp(answer{1},'Yes')
        cTimelapse.trapsPresent=false;
    else
        cTimelapse.trapsPresent=true;
    end
else
    cTimelapse.trapsPresent=trapsPresent;
end

if (nargin<4 || isempty(image_rotation)) 
    if cTimelapse.trapsPresent
        h=figure;imshow(image,[]);
        prompt = {'Enter the rotation required to orient opening of traps to the left'};
        dlg_title = 'Rotation';
        num_lines = 1;
        def = {'0'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        cTimelapse.image_rotation=str2num(answer{1});
        close(h);
        
        
        prompt = {'Enter desired image rescaling value'};
        dlg_title = 'Scaling';
        num_lines = 1;
        def = {''};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        cTimelapse.imScale=str2num(answer{1});
    else
        cTimelapse.image_rotation=0;
    end
else
    cTimelapse.image_rotation=image_rotation;
    cTimelapse.imScale=imScale;
end

