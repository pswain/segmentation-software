function createTimelapsePositions(cExperimentOmero,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad,traps_present)
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

oImages=cExperimentOmero.omeroDs.linkedImageList;

chNames=cExperimentOmero.experimentInformation.channels;
if isempty(searchString)
    ch = menu('Choose channel used in segmentation (brightfield/DIC images)',chNames);
    searchString=chNames{ch};
end

if ischar(positionsToLoad)&&strcmp(positionsToLoad,'all')
    positionsToLoad=1:oImages.size;
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
    traps_present = cExperimentOmero.trapsPresent;
end



cExperimentOmero.searchString=searchString;
cExperimentOmero.pixelSize=pixelSize;
cExperimentOmero.image_rotation=image_rotation;
cExperimentOmero.timepointsToLoad=timepointsToLoad;
cExperimentOmero.trapsPresent = traps_present;
% Start adding arguments to experiment creation protocol log:

cExperimentOmero.logger.add_arg('Omero experiment name',cExperimentOmero.rootFolder);
cExperimentOmero.logger.add_arg('Temporary working directory',cExperimentOmero.saveFolder);

if isempty(cExperimentOmero.timepointsToLoad)
    cExperimentOmero.logger.add_arg('Timepoints to load','all');
else
    cExperimentOmero.logger.add_arg('Timepoints to load',cExperimentOmero.timepointsToLoad);
end
if ~isempty(cExperimentOmero.pixelSize)
    
end
% The other arguments are added and the protocol started after the first
% call to loadTimelapse below...

try
    
    %Get the image names - allows the correct image to be loaded for each
    %position
    oImNames=cell(oImages.size,1);
    for im=0:oImages.size-1
        oImNames{im+1}=char(oImages.get(im).getName.getValue);
    end
       
    %% Load timelapses
    for i=1:length(positionsToLoad)
        currentPos=positionsToLoad(i);
        oImIndex=find(strcmp(oImNames,cExperimentOmero.dirs{currentPos}))-1;
        cExperimentOmero.cTimelapse=timelapseTrapsOmero(oImages.get(oImIndex),cExperimentOmero,currentPos);
        
        % Trigger a PositionChanged event to notify experimentLogging
        experimentLogging.changePos(cExperimentOmero,currentPos,cExperimentOmero.cTimelapse);
        cExperimentOmero.cTimelapse.metadata = cExperimentOmero.metadata;
        cExperimentOmero.cTimelapse.metadata.posname = cExperimentOmero.dirs{currentPos};
        cExperimentOmero.cTimelapse.loadTimelapse(cExperimentOmero.searchString,cExperimentOmero.image_rotation,cExperimentOmero.trapsPresent,cExperimentOmero.timepointsToLoad,cExperimentOmero.pixelSize);
        
        cExperimentOmero.pixelSize=cExperimentOmero.cTimelapse.pixelSize;
        cExperimentOmero.image_rotation=cExperimentOmero.cTimelapse.image_rotation;
        cExperimentOmero.trapsPresent = cExperimentOmero.cTimelapse.trapsPresent;
        cExperimentOmero.timepointsToProcess = cExperimentOmero.cTimelapse.timepointsToProcess;
        
        % After the first call to loadTimelapse, the arguments should now all
        % be set, so start logging the creation protocol:
        if i==1
            cExperimentOmero.logger.add_arg('Default segmentation channel',cExperimentOmero.searchString);
            cExperimentOmero.logger.add_arg('Traps present',cExperimentOmero.trapsPresent);
            cExperimentOmero.logger.add_arg('Image rotation',cExperimentOmero.image_rotation);
            cExperimentOmero.logger.add_arg('Pixel size',cExperimentOmero.pixelSize);
            cExperimentOmero.logger.start_protocol('creating new experiment',length(positionsToLoad));
        end
        
        cExperimentOmero.saveTimelapseExperiment(currentPos,false);%The false input tells this function no to save the cExperiment each time. Will speed it up a bit
    end
    
    % load the default cellVision file.
    cCellVision = cExperimentOmero.loadDefaultCellVision;
    cExperimentOmero.cCellVision = cCellVision;
     
    % set a housekeeping variables:
    
    %whether a position has been segmented
    cExperimentOmero.posSegmented = false(size(cExperimentOmero.dirs));
    
    % this is true when it is appropriate to reset old trapInfo for some
    % reason (changes in cellVision model typically).
    cExperimentOmero.clearOldTrapInfo = false(size(cExperimentOmero.dirs));
    
    cExperimentOmero.saveExperiment;
    
    % if experiment has no traps, the trap tracking must still be run to
    % initialise the trapsInfo. This causes no end of confusion, so I have
    % done it here automatically.
    if ~cExperimentOmero.trapsPresent
        cExperimentOmero.trackTrapsInTime(positionsToLoad);
    end
    
    % Finish logging protocol
    cExperimentOmero.logger.complete_protocol;
catch err
    cExperimentOmero.logger.protocol_error;
    rethrow(err);
end

end