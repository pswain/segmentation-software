function loadTimelapseScot(cTimelapse,timelapseObj)

%% Read images into timelapse class
% Timelapse is a seletion of images from a file. These images must be
% loaded in the correct order from low to high numbers to ensure that the
% cell tracking performs correctly, and they must be rotated to ensure the
% trap correctly aligns with the images

timepoint_index=0;
for n=1:size(timelapseObj.ImageFileList.file_details,2)
    filename=[timelapseObj.ImageFileList.directory '/' timelapseObj.ImageFileList(timelapseObj.Main).file_details(timelapseObj.CurrentFrame).timepoints.name];
    
    cTimelapse.cTimepoint(timepoint_index+1).filename{1}=filename;
    cTimelapse.cTimepoint(timepoint_index+1).trapLocations=[];
    timepoint_index=timepoint_index+1;
end

if nargin>=5 && ~isempty(timepointsToLoad)
    if max(timepointsToLoad)>length(cTimelapse.cTimepoint)
        timepointsToLoad=timepointsToLoad(timepointsToLoad<=length(cTimelapse.cTimepoint));
    end
    cTimelapse.cTimepoint=cTimelapse.cTimepoint(timepointsToLoad);
end

image=imread(cTimelapse.cTimepoint(1).filename{1});
if nargin<3 || isempty(magnification)
    figure(91);imshow(image,[]);
    prompt = {'Enter the camera pixel size in microns with the objective used'};
    dlg_title = 'Objective';
    num_lines = 1;
    def = {'60'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cTimelapse.pixelSize=str2num(answer{1});
else
    cTimelapse.pixelSize=pixelSize;
end

if nargin<4 || isempty(image_rotation)
    figure(91);imshow(image,[]);
    prompt = {'Enter the rotation required to orient opening of traps to the left'};
    dlg_title = 'Rotation';
    num_lines = 1;
    def = {'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cTimelapse.image_rotation=str2num(answer{1});
else
    cTimelapse.image_rotation=image_rotation;
end
