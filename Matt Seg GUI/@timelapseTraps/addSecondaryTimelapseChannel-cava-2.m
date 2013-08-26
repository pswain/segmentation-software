function addSecondaryTimelapseChannel(cTimelapse,searchString)

% pattern='\d{5,6}'
% regexp(cTimelapse.cTimepoint(1).filename{1},p1,'match')

if nargin<2
    searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'GFP'});
end


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

tic
searchResult=regexp(files,searchString,'start');
toc

timepoint_index=0;
folder=[folder '/']
% cTimelapse=cell(1)
for i=1:length(cTimelapse.cTimepoint)
    pattern='\d{5,6}';
    fileNum=regexp(cTimelapse.cTimepoint(i).filename{1},pattern,'match');
    
    p1=[fileNum{1} '_' searchString{1}]
    match=regexp(files(:),p1,'match');
    loc=find(~cellfun('isempty',match));
    cTimelapse.cTimepoint(i).filename{end+1}=[folder files{loc}];
    
end

% for n = 1:length(files);
%     n
%     searchResult=regexp(files{n},searchString,'start');
%     if ~isempty(searchResult{1})
%         pattern='\d{5,6}';
%         fileNum=regexp(files{n},pattern,'match');
%         
%         
%             match=regexp(cTimelapse.cTimepoint(i).filename{1},fileNum,'match');
%             if ~isempty(match{1})
%                 cTimelapse.cTimepoint(i).filename{end+1}=files{n};
%                 break;
%             end
%         end
%     end
% end
%             
%     if length(strfind(files{n},'tif'))| length(strfind(files{n},'png'))
%         if length(strfind(files{n},searchString))
%             image=imread([folder files{n}]);
%             if mean(image(:))>10
%                 cTimelapse.cTimepoint(timepoint_index+1).secondaryImage=imrotate(image,cTimelapse.image_rotation);
%                 timepoint_index=timepoint_index+1;
%             end
%         end
%     end
% end

