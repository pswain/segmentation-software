function addSecondaryTimelapseChannel(cTimelapse,searchString)

folder=cTimelapse.timelapseDir;
tempdir=dir(folder);
nfiles=0;
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
timepoint_index=0;
folder=[folder '/']
% cTimelapse=cell(1)
for n = 1:length(files);
    if length(strfind(files{n},'tif'))| length(strfind(files{n},'png'))
        if length(strfind(files{n},searchString))
            image=imread([folder files{n}]);
            if mean(image(:))>10
                cTimelapse.cTimepoint(timepoint_index+1).secondaryImage=imrotate(image,cTimelapse.image_rotation);
                timepoint_index=timepoint_index+1;
            end
        end
    end
end

