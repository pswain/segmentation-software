function addSecondaryTimelapseChannel(cTimelapse,searchString)

%%Search for and add another image channel to the timelapse.
%---------------------------------------------------------
%SYNOPSIS:  addSecondaryTimelapseChannel(cTimelapse,searchString)
%           Search cTimelapse.timelapseDir for images matching a pattern
%           given by the original files and appended by searchString.

if nargin<2
    searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'GFP'});
end

searchResult=regexp(cTimelapse.channelNames,searchString,'start');
loc= ~cellfun('isempty',searchResult);
if sum(loc)>0
    errordlg('Error, a channel with that name already exists');
end

cTimelapse.channelNames{end+1}=searchString{1};

folder=cTimelapse.timelapseDir;
tempdir=dir(folder);
nfiles=0;
names=cell(1);
for i=1:length(tempdir)
    names{i}=tempdir(i).name;
end

files=sort(names);

searchResult=regexp(files,searchString,'start');

timepoint_index=0;
folder=[folder '/'];
% cTimelapse=cell(1)
if strcmp(cTimelapse.fileSoure,'swain-batman')
    for i=1:length(cTimelapse.cTimepoint)
        %Match a pattern to the filename using regex
        pattern='\d{5,6}';
        fileNum=regexp(cTimelapse.cTimepoint(i).filename{1},pattern,'match');

        p1=[fileNum{end} '_' searchString{1}];
        match=regexp(files(:),p1,'match');
        loc= ~cellfun('isempty',match);
        if sum(loc)>0
    %         cTimelapse.cTimepoint(i).filename{length(cTimelapse.channelNames)}=[folder files{loc}];
    %         cTimelapse.cTimepoint(i).filename(end+1:end+sum(loc))=(cellstr([repmat(folder,sum(loc),1) vertcat(files{loc})]));
            cTimelapse.cTimepoint(i).filename(end+1:end+sum(loc))=(cellstr(vertcat(files{loc})));

        end

    end
elseif strcmp(cTimelapse.fileSoure,'tyers')
    for i=1:length(cTimelapse.cTimepoint)
        pattern = '_t\d{2}';
        fileNum=regexp(cTimelapse.cTimepoint(i).filename{1},pattern,'match');
       
        p1=[searchString{1} '_\w{4}' fileNum{end}];        
        match=regexp(files(:),p1,'match');
        loc= ~cellfun('isempty',match);
        if sum(loc)>0
            cTimelapse.cTimepoint(i).filename(end+1:end+sum(loc))=(cellstr(vertcat(files{loc})));

        end
        
    end
    
end
%add an offset field that can later be edited to offset the new image
%relative to the DIC image when returning timepoints
cTimelapse.offset(find(strcmp(searchString,cTimelapse.channelNames)),:) = [0 0];


%add a background correction entry that can later be set to be the matrix
%by which you want to multiply the image to correct for uneven
%illumination. Should come from illumination measurements.
cTimelapse.BackgroundCorrection{find(strcmp(searchString,cTimelapse.channelNames))} = [];

