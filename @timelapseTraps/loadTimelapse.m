function loadTimelapse(cTimelapse,searchString,pixelSize,image_rotation,timepointsToLoad)

folder=cTimelapse.timelapseDir;
tempdir=dir(folder);
nfiles=0;
names=cell(1);
for i=1:length(tempdir)
    names{i}=tempdir(i).name;
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
for ss=1:length(searchString)
    timepoint_index=0;
    for n = 1:length(files);
        if length(strfind(files{n},'tif'))| length(strfind(files{n},'png'))
            if length(strfind(files{n},searchString{ss}))
                cTimelapse.cTimepoint(timepoint_index+1).filename{ss}=[folder files{n}];
                cTimelapse.cTimepoint(timepoint_index+1).trapLocations=[];
                timepoint_index=timepoint_index+1;
            end
        end
    end
end

if nargin>=5 && ~isempty(timepointsToLoad)
    if max(timepointsToLoad)>length(cTimelapse.cTimepoint)
        timepointsToLoad=timepointsToLoad(timepointsToLoad<=length(cTimelapse.cTimepoint));
    end
    cTimelapse.cTimepoint=cTimelapse.cTimepoint(timepointsToLoad);
end

image=imread(cTimelapse.cTimepoint(1).filename{1});
if nargin<3 || isempty(pixelSize)
    h=figure;imshow(image,[]);
    prompt = {'Enter the size of the camera pixels (microns) with the objective used'};
    dlg_title = 'pixelSize';
    num_lines = 1;
    def = {'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cTimelapse.pixelSize=str2num(answer{1});
    close(h);
else
    cTimelapse.pixelSize=pixelSize;
end

%
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
    else
        cTimelapse.image_rotation=0;
    end
else
    cTimelapse.image_rotation=image_rotation;
end
