function createTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad,traps_present)
% createTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad,traps_present)
%
% goes through the folders in the rootDir of cExperiment and creates a
% timelapseTraps object for each one, instantiating the cTimepoint
% structure array using the files containing the string searchString (see
% timelapseTraps.loadTimelapse for details). Any input not provided is
% defined by GUI.
%
% inputs are all those passed to loadTimelapse method of timelapseTraps in
% creating each timelapse.
%
% See also TIMELAPSETRAPS.LOADTIMELAPSE

if nargin<2 || isempty(searchString)
    searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'Brightfield_002'});
    searchString = searchString{1};
end

if nargin<3 || strcmp(positionsToLoad,'all')
    positionsToLoad=1:length(cExperiment.dirs);
end

if nargin<4
    pixelSize=[];
end

if nargin<5
    image_rotation=[];
end

%timepoints to load functionality has been superceded by
%timepointstoProcess, which is done after the object has been created and
%just limits processing.
if nargin<6
    timepointsToLoad=[];
end

if nargin<7
    traps_present = cExperiment.trapsPresent;
end

cExperiment.searchString=searchString;
cExperiment.pixelSize=pixelSize;
cExperiment.image_rotation=image_rotation;
cExperiment.timepointsToLoad=timepointsToLoad;
cExperiment.trapsPresent = traps_present;
cExperiment.channelNames{end+1}=searchString;
% Start adding arguments to experiment creation protocol log:
cExperiment.logger.add_arg('Root folder',cExperiment.rootFolder);
cExperiment.logger.add_arg('Save folder',cExperiment.saveFolder);

if isempty(cExperiment.timepointsToLoad)
    cExperiment.logger.add_arg('Timepoints to load','all');
else
    cExperiment.logger.add_arg('Timepoints to load',cExperiment.timepointsToLoad);
end

% The other arguments are added and the protocol started after the first
% call to loadTimelapse below...

try
    
    %% Load timelapses
    for i=1:length(positionsToLoad)
        currentPos=positionsToLoad(i);
        cExperiment.cTimelapse=timelapseTraps([cExperiment.rootFolder filesep cExperiment.dirs{currentPos}]);
        % Trigger a PositionChanged event to notify experimentLogging
        experimentLogging.changePos(cExperiment,currentPos,cExperiment.cTimelapse);
        
        cExperiment.cTimelapse.loadTimelapse(cExperiment.searchString,cExperiment.image_rotation,cExperiment.trapsPresent,cExperiment.timepointsToLoad,cExperiment.pixelSize);
        
        cExperiment.pixelSize=cExperiment.cTimelapse.pixelSize;
        cExperiment.image_rotation=cExperiment.cTimelapse.image_rotation;
        
        cExperiment.trapsPresent = cExperiment.cTimelapse.trapsPresent;
        cExperiment.timepointsToProcess = cExperiment.cTimelapse.timepointsToProcess;
        
        % After the first call to loadTimelapse, the arguments should now all
        % be set, so start logging the creation protocol:
        if i==1
            cExperiment.logger.add_arg('Default segmentation channel',cExperiment.searchString);
            cExperiment.logger.add_arg('Traps present',cExperiment.trapsPresent);
            cExperiment.logger.add_arg('Image rotation',cExperiment.image_rotation);
            cExperiment.logger.add_arg('Pixel size',cExperiment.pixelSize);
            cExperiment.logger.start_protocol('creating new experiment',length(positionsToLoad));
        end
        
        cExperiment.saveTimelapseExperiment(currentPos);
    end
    
    % load the default cellVision file.
    cCellVision = cExperiment.loadDefaultCellVision;
    cExperiment.cCellVision = cCellVision;
    
    cExperiment.saveExperiment;
    
    % if experiment has no traps, the trap tracking must still be run to
    % initialise the trapsInfo. This causes no end of confusion, so I have
    % done it here automatically.
    if ~cExperiment.trapsPresent
        cExperiment.trackTrapsInTime(positionsToLoad);
    end
    
    % Finish logging protocol
    cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end