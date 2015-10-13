function loadTimelapse(cTimelapse,searchString,magnfication,image_rotation,trapsPresent,timepointsToLoad,imScale)


cTimelapse.channelNames=searchString;
if isempty(cTimelapse.omeroImage)
    folder=cTimelapse.timelapseDir;
    tempdir=dir(folder);
    nfiles=0;
    names=cell(1);
    for i=1:length(tempdir)
        names{i}=tempdir(i).name;
    end

files=sort(names);
folder=[folder '/']
%% Read images into timelapse class
% Timelapse is a seletion of images from a file. These images must be
% loaded in the correct order from low to high numbers to ensure that the
% cell tracking performs correctly, and they must be rotated to ensure the
% trap correctly aligns with the images

timepoint_index=0;

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

else
    %Image is from Omero database
    %Define cTimepoint structure
    cTimepointTemplate = struct('filename',[],'trapLocations',[],...
                            'trapInfo',[],'trapMaxCell',[],'trapMaxCellUTP',[]);

    cTimelapse.cTimepoint = cTimepointTemplate;
       
    %Correct Z position - load image from the middle of the stack
    pixels=cTimelapse.omeroImage.getPrimaryPixels;
    sizeT=pixels.getSizeT().getValue();
    cTimelapse.cTimepoint(sizeT).filename=[];%This makes sure cTimepoint has the correct length
    cTimelapse.timepointsToProcess = 1:sizeT;
    sizeZ = pixels.getSizeZ().getValue();
    z=round(sizeZ/2);
    %Correct channel - defined by searchString
    c=find(strcmp(searchString,cTimelapse.OmeroDatabase.Channels));
    t=1;
    image=cTimelapse.OmeroDatabase.downloadSlice(cTimelapse.omeroImage,z,t,c);
end

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

