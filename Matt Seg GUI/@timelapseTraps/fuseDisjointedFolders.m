function fuseDisjointedFolders(cTimelapse,newFolder)
% Elco - not sure what this function does.Looks like it adds timepoints
% from one folder to a timelapse made in another folder. Probably doesn't
% work very well anymore and should probably be ignored.

if nargin<2
    newFolder=uigetdir(cTimelapse.timelapseDir,'Please Select the directory you want to add to this one');
end
tempdir=dir(newFolder);
newFolder=[newFolder '/']

names=cell(1);
for i=1:length(tempdir)
    names{i}=tempdir(i).name;
end

files=sort(names);
%% Read images into timelapse class
% Timelapse is a seletion of images from a file. These images must be
% loaded in the correct order from low to high numbers to ensure that the
% cell tracking performs correctly, and they must be rotated to ensure the
% trap correctly aligns with the images
largestTimepoint = 0;
searchString=cTimelapse.channelNames;

for ss=1%:length(searchString)
    timepoint_index=length(cTimelapse.cTimepoint);
    for n = 1:length(files);
        if isempty(strfind(files{n},'tif'))|| isempty(strfind(files{n},'png')) || isempty(strfind(files{n},'TIF'))
            if length(strfind(files{n},searchString{1}))
                cTimelapse.cTimepoint(timepoint_index+1).filename{ss}=[newFolder files{n}];
                cTimelapse.cTimepoint(timepoint_index+1).trapLocations=[];
                timepoint_index=timepoint_index+1;
            end
        end
    end
    largestTimepoint = max([timepoint_index;largestTimepoint]);
end

cTimelapse.timepointsToProcess = 1:largestTimepoint;

for ssInd=2:length(searchString)

    %% Read images into timelapse class
    % Timelapse is a seletion of images from a file. These images must be
    % loaded in the correct order from low to high numbers to ensure that the
    % cell tracking performs correctly, and they must be rotated to ensure the
    % trap correctly aligns with the images

    for i=1:length(cTimelapse.cTimepoint)
        %Match a pattern to the filename using regex
        pattern='\d{5,9}';
        fileNum=regexp(cTimelapse.cTimepoint(i).filename{1},pattern,'match');
        
        match1=regexp(files(:),fileNum{end},'match');
        match2=regexp(files(:),searchString{ssInd},'match');
        loc1= ~cellfun('isempty',match1);
        loc2= ~cellfun('isempty',match2);
        loc=loc1&loc2;
        if sum(loc)>0
            cTimelapse.cTimepoint(i).filename(end+1:end+sum(loc))=(cellstr(vertcat(files{loc})));
        end
    end
end

