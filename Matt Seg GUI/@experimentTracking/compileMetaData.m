function compileMetaData(cExperiment,extractedTimepoints,progress_bar)
%experimentTracking.compileMetaData Compile meta data into cellInf
%   This function adds the meta data to the cellInf array (only for the
%   first channel), including the generation of a times field that provides
%   a time of acquisition for each cell at each time point.

% First check that this cExperiment has been compiled:
if ~isprop(cExperiment,'cellInf') || isempty(cExperiment.cellInf)
    error('The cellInf hasn''t been compiled for this cExperiment.');
end

close_progress = false;
pop_progress_bar = false;

if nargin<3 || ~isa(progress_bar,'Progress')
    % Initialise a progress bar
    progress_bar = Progress();
    % Centre the dialog box
    progress_bar.frame.setLocationRelativeTo([]);
    % Set the progress bar title
    progress_bar.frame.setTitle('Compiling meta data...');
    close_progress = true;
end

% Check that the log file has been parsed for this cExperiment
if ~isprop(cExperiment,'metadata') || isempty(cExperiment.metadata)
    cExperiment.parseLogFile([],progress_bar);
end

% If we still don't have meta data, silently fail
if ~isprop(cExperiment,'metadata') || isempty(cExperiment.metadata)
    if close_progress
        progress_bar.frame.dispose;
    end
    return
end

approxNtimepoints = size(cExperiment.metadata.logTimes,2);

%% Determine the timepoints for which extraction was performed if not provided:
extractedPositions = sort(unique(cExperiment.cellInf(1).posNum));
if nargin<2 || isempty(extractedTimepoints)
    extractedTimepoints = false(max(extractedPositions(:)),approxNtimepoints);
    
    try
        % First run a test call to see if the cExperiment can access cTimelapse
        cExperiment.returnTimelapse(extractedPositions(1));
        
        progress_bar.push_bar('Determining extracted timepoints...',1,...
            length(extractedPositions));
        pop_progress_bar = true;
        
        for i=1:length(extractedPositions)
            progress_bar.set_val(i);
            ipos=extractedPositions(i);
            cTimelapse = cExperiment.returnTimelapse(ipos);
            extractedTimepoints(ipos,1:length(cTimelapse.timepointsProcessed)) = ...
                cTimelapse.timepointsProcessed;
            delete(cTimelapse);
        end
        
    catch
        warning('Cannot load cTimelapse for this cExperiment. Using cExperiment timepointsToProcess.');
        extractedTimepoints(:,cExperiment.timepointsToProcess) = true;
    end
else
    if size(extractedTimepoints,1)<max(extractedPositions(:)) || ...
            size(extractedTimepoints,2) < approxNtimepoints
        error('The provided "extractedPositions" argument has the wrong shape.');
    end
end

%% Refactor the arrays to the same format as cellInf arrays:
positions = cExperiment.cellInf(1).posNum;
posNames = cExperiment.dirs;
posIndices = cellfun(@(s) find(strcmpi(cExperiment.metadata.logPosNames,s)), posNames);

% Truncate the array to include the same number of timepoints as cellInf
timesInMinutes = cExperiment.metadata.logTimes(:,1:approxNtimepoints);
extractedTimepoints = extractedTimepoints(:,1:approxNtimepoints);

% Set cell times based on that cell's position
timesInMinutes = timesInMinutes(posIndices(positions),:);
extractedTimepoints = extractedTimepoints(positions,:);

%% Update cExperiment:
cExperiment.cellInf(1).date = cExperiment.metadata.date;
cExperiment.cellInf(1).times = timesInMinutes;
cExperiment.cellInf(1).extractedTimepoints = extractedTimepoints;
cExperiment.cellInf(1).annotations = cExperiment.metadata;

% Clean up progress bar:
if pop_progress_bar
    progress_bar.pop_bar; % finished reading all timepoints
end
if close_progress
    progress_bar.frame.dispose;
end

end