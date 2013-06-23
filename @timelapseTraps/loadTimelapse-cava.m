function loadTimelapse(cTimelapse,searchString,image_rotation)

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
if nargin<3
    image_rotation=[];
end

timepoint_index=0;
folder=[folder '/']

% cTimelapse.cTimepoint(1)=struct('filename');
for ss=1:length(searchString)
    timepoint_index=0;
    for n = 1:length(files);
        if length(strfind(files{n},'tif'))| length(strfind(files{n},'png'))
            if length(strfind(files{n},searchString{ss}))
                cTimelapse.cTimepoint(timepoint_index+1).filename{ss}=[folder files{n}];
                timepoint_index=timepoint_index+1;
            end
        end
    end
end

image=imread(cTimelapse.cTimepoint(1).filename{1});
if ~length(image_rotation)
    figure(1);imshow(image,[]);
    prompt = {'Enter the magnifcation of the objective used'};
    dlg_title = 'Objective';
    num_lines = 1;
    def = {'60'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cTimelapse.magnification=str2num(answer{1});
end
