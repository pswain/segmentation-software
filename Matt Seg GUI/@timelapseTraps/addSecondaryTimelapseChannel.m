function addSecondaryTimelapseChannel(cTimelapse,searchString)
% addSecondaryTimelapseChannel(cTimelapse,searchString)
%
% searchString   -  the string or "cellstr" of strings used to identify new
%                   channels by file name.
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
% returnTimepoint code as a stack which is projected

if nargin<2 || isempty(searchString)
    searchString = inputdlg('Enter the string to search for the brightfield/DIC images'...
        ,'SearchString',1,cTimelapse.channelNames(end));
    searchString = searchString{1};
end

if ischar(searchString)
    searchString = cellstr(searchString);
end
assert(iscellstr(searchString),...
    'Specify channels to add either as a single string, or a cell array of strings');

matching_channels = ismember(searchString,cTimelapse.channelNames);
if any(matching_channels)
    error_message = sprintf('Error, the channel(s) %s already exist.',...
        strjoin(searchString(matching_channels),', '));
    errordlg(error_message); error(error_message); %#ok<SPERR>
end

cTimelapse.channelNames = [cTimelapse.channelNames,searchString];

folder = cTimelapse.timelapseDir;
tempdir = dir(folder);
files = {tempdir(:).name};

% throw away hidden files in unix system
to_keep = cellfun('isempty',regexp(files,'^\.','once'));
files = files(to_keep);

% Don't add files already stored in cTimelapse.
files_already_added = [cTimelapse.cTimepoint(:).filename];
files = setdiff(files,files_already_added);
files = sort(files);

% The first file saved at each time point serves as a reference to
% determine the numeric ID of that timepoint:
reference_files = arrayfun(@(tp) tp.filename{1},cTimelapse.cTimepoint,...
    'UniformOutput',false);

%Match a pattern to the filename using regex
%expects each file to have a long number (6-9 digits) that
%determines its timepoint.
%extract the timepoint number for the file which was used to
%instantiate the timepoint (filename{1}). This is taken to be the
%time of the timepoint and is used to select files from the same
%timepoint with a different channel.
if strcmp(cTimelapse.fileSoure,'swain-batman')
    % Pre-calculate the file timepoint numbers:
    code_timing = tic;
    fileNums=regexp(reference_files,'\d{5,9}','match','once');
    
    % Determine files to add for each timepoint:
    for i=1:length(cTimelapse.cTimepoint)
        % Filter files to those at this timepoint:
        match_timepoint_regexp = ['^[^.].*',fileNums{i}];
        timepoint_loc = ~cellfun(@isempty,...
            regexp(files(:),match_timepoint_regexp,'start','once'));
        timepoint_files = files(timepoint_loc);
        files_index = 1:length(files);
        files_index = files_index(timepoint_loc);
        
        % Add each of the requested channels for this timepoint:
        for j=1:length(searchString)
            searchString_j = searchString{j};
            
            % not hidden + timepoint + searchString_j
            match_string = ['^[^.].*' fileNums{i} '.*' searchString_j ];
            
            match = regexp(timepoint_files,match_string,'start');
            
            loc=~cellfun('isempty',match);
            
            if any(loc)
                cTimelapse.cTimepoint(i).filename = ...
                    unique([cTimelapse.cTimepoint(i).filename(:);cellstr(vertcat(timepoint_files{loc}))]);
%                 timepoint_files(loc) = [];
%                 files(files_index(loc)) = [];
%                 files_index = files_index(1:(end-sum(loc)));
            end
        end
        % Ignore all files from this timepoint in future iterations
        files(timepoint_loc) = [];
    end
    fprintf('Matching channels: %.2f s',toc(code_timing));
elseif strcmp(cTimelapse.fileSoure,'tyers')
    % images from the tyers lab are stored according to a different structure,
    % so have a different pattern recognition.
    %
    % Additional types can be added by adding additional elseif statements.
    fileNums=regexp(reference_files,'_t\d{2}','match','once');
    for i=1:length(cTimelapse.cTimepoint)
        % Add each of the requested channels for this timepoint:
        for j=1:length(searchString)
            searchString_j = searchString{j};
            p1=[searchString_j '_\w{4}' fileNums{i}];
            match=regexp(files(:),p1,'match');
            loc= ~cellfun('isempty',match);
            if sum(loc)>0
                cTimelapse.cTimepoint(i).filename(end+1:end+sum(loc))=(cellstr(vertcat(files{loc})));
            end
        end
    end
end

for j=1:length(searchString)
    searchString_j = searchString{j};
    %add an offset field that can later be edited to offset the new image
    %relative to the DIC image when returning timepoints
    cTimelapse.offset(find(strcmp(searchString_j,cTimelapse.channelNames)),:) = [0 0];
    
    
    %add a background correction entry that can later be set to be the matrix
    %by which you want to multiply the image to correct for uneven
    %illumination. Should come from illumination measurements.
    cTimelapse.BackgroundCorrection{find(strcmp(searchString_j,cTimelapse.channelNames))} = [];
    
    
    %add an error model entry that can later be set to be an error model object which can be fed pixel
    %data values and spits out the estimated shot noise.
    cTimelapse.ErrorModel{find(strcmp(searchString_j,cTimelapse.channelNames))} = [];
    
end

end