function addSecondaryTimelapseChannel(cTimelapse,searchString)
% addSecondaryTimelapseChannel(cTimelapse,searchString)
%
% searchString   :  the string used to identify new
%                   files.
%
% Associates new files to each timepoint of the timelapseTraps object by
% extracting the timepoint number from the first file
% (cTimelapse.cTimepoint(i).filename{1} and then identifying files in the
% timelapseDir with both the timepoint number and the searchString
% (searchString) in them. This assumes a certain naming structure for
% the files which can be different depending on the fileSource field of the
% cTimelapse. For Images from Swain microscope assumes a 5-9 digit number
% for timepoint number.
% Numerous files (e.g. z stacks) may be added by a single
% addSecondaryTimelapseChannel call, these are handled by the
% returnTimepoint code as a stack which is projected, but care should be
% taken. the same file might also be added numerous time by irresponsible
% calls (such as adding 'GFP' then 'GFP_001')

if nargin<2 || isempty(searchString)
    searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'GFP'});
    searchString = searchString{1};
elseif ~ischar(searchString)
    error('searchString should be a string')
end


searchResult=regexp(cTimelapse.channelNames,searchString,'start');
loc= ~cellfun('isempty',searchResult);
if sum(loc)>0
    errordlg('Error, a channel with that name already exists');
    error('Error, a channel with that name already exists');
end

cTimelapse.channelNames{end+1}=searchString;

folder=cTimelapse.timelapseDir;
tempdir=dir(folder);
files = {tempdir(:).name};

files_already_added = [cTimelapse.cTimepoint(:).filename];

% don't add files already stored in cTimelapse.
files = setdiff(files,files_already_added);

files=sort(files);


if strcmp(cTimelapse.fileSoure,'swain-batman')
    for i=1:length(cTimelapse.cTimepoint)
        %Match a pattern to the filename using regex
        %expects each file to have a long number (6-9 digits) that
        %determines its timepoint.
        %extract the timepoint number for the file which was used to
        %instantiate the timepoint (filename{1}). This is taken to be the
        %time of the timepoint and is used to select files from the same
        %timepoint with a different channel.
        pattern='\d{5,9}';
        fileNum=regexp(cTimelapse.cTimepoint(i).filename{1},pattern,'match');

        match1=regexp(files(:),fileNum{end},'match');
        match2=regexp(files(:),searchString,'match');
        loc1= ~cellfun('isempty',match1);
        loc2= ~cellfun('isempty',match2);
        loc=loc1&loc2;
        if sum(loc)>0
            cTimelapse.cTimepoint(i).filename(end+1:end+sum(loc))=(cellstr(vertcat(files{loc})));
            files(loc)=[];

        end

    end
% images from the tyers lab are stored according to a different structure,
% so have a different pattern recognition.
elseif strcmp(cTimelapse.fileSoure,'tyers')
    for i=1:length(cTimelapse.cTimepoint)
        pattern = '_t\d{2}';
        fileNum=regexp(cTimelapse.cTimepoint(i).filename{1},pattern,'match');
       
        p1=[searchString '_\w{4}' fileNum{end}];        
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


%add an error model entry that can later be set to be an error model object which can be fed pixel
%data values and spits out the estimated shot noise.
cTimelapse.ErrorModel{find(strcmp(searchString,cTimelapse.channelNames))} = [];

