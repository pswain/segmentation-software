function createTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad,magnification,imScale,traps_present)
% createTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad,magnification,imScale,traps_present)
%
% goes through the folders in the rootDir of cExperiment and creates a
% timelapseTraps object for each one, instantiating the cTimepoint
% structure array using the files containing the string searchStrinf (see
% timelapseTraps.loadTimelapse for details). Any input not provided is
% defined by GUI.
%
% inputs are all those passed to loadTimelapse method of timelapseTraps in
% creating each timelapse. Omero ignores the searchString input
%
% See also TIMELAPSETRAPS.LOADTIMELAPSE

oImages=cExperiment.omeroDs.linkedImageList;

chNames=cExperiment.experimentInformation.channels;
ch = menu('Choose channel used in segmentation (brightfield/DIC images)',chNames);
searchString=chNames(ch);

positionsToLoad=1:oImages.size;

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
    magnification = [];
end

if nargin<8
    imScale = 'gui';
end

if nargin<9
    traps_present = cExperiment.trapsPresent;
end



cExperiment.searchString=searchString;
cExperiment.pixelSize=pixelSize;
cExperiment.image_rotation=image_rotation;
cExperiment.timepointsToLoad=timepointsToLoad;
cExperiment.magnification = magnification;
cExperiment.imScale = imScale;
cExperiment.trapsPresent = traps_present;
cExperiment.channelNames{end+1}=searchString{1};
% Start adding arguments to experiment creation protocol log:

cExperiment.logger.add_arg('Omero experiment name',cExperiment.rootFolder);
cExperiment.logger.add_arg('Temporary working directory',cExperiment.saveFolder);

if isempty(cExperiment.timepointsToLoad)
    cExperiment.logger.add_arg('Timepoints to load','all');
else
    cExperiment.logger.add_arg('Timepoints to load',cExperiment.timepointsToLoad);
end
if ~isempty(cExperiment.pixelSize)
    cExperiment.logger.add_arg('Pixel size',cExperiment.pixelSize);
end
% The other arguments are added and the protocol started after the first
% call to loadTimelapse below...

try
    
    %% Load timelapses
    for i=1:length(positionsToLoad)
        currentPos=positionsToLoad(i);

        cExperiment.cTimelapse=timelapseTraps(oImages.get(i-1),cExperiment.OmeroDatabase);
        
        % Trigger a PositionChanged event to notify experimentLogging
        experimentLogging.changePos(cExperiment,currentPos,cExperiment.cTimelapse);
        
        cExperiment.cTimelapse.loadTimelapse(cExperiment.searchString,cExperiment.magnification,cExperiment.image_rotation,cExperiment.trapsPresent,cExperiment.timepointsToLoad,cExperiment.imScale);
        
        cExperiment.magnification=cExperiment.cTimelapse.magnification;
        cExperiment.imScale=cExperiment.cTimelapse.imScale;
        cExperiment.image_rotation=cExperiment.cTimelapse.image_rotation;
        cExperiment.trapsPresent = cExperiment.cTimelapse.trapsPresent;
        cExperiment.timepointsToProcess = cExperiment.cTimelapse.timepointsToProcess;
        
        % After the first call to loadTimelapse, the arguments should now all
        % be set, so start logging the creation protocol:
        if i==1
            cExperiment.logger.add_arg('Default segmentation channel',cExperiment.searchString);
            cExperiment.logger.add_arg('Traps present',cExperiment.trapsPresent);
            cExperiment.logger.add_arg('Image rotation',cExperiment.image_rotation);
            cExperiment.logger.add_arg('Magnification',cExperiment.magnification);
            if ~isempty(cExperiment.imScale)
                cExperiment.logger.add_arg('Image scale',cExperiment.imScale);
            end
            cExperiment.logger.start_protocol('creating new experiment',length(positionsToLoad));
        end
        
        cExperiment.saveTimelapseExperiment(currentPos,false);%The false input tells this function no to save the cExperiment each time. Will speed it up a bit
    end
    
    % load the default cellVision file.
    cCellVision = cExperiment.loadDefaultCellVision;
    cExperiment.cCellVision = cCellVision;
    
    
    cExperiment.saveExperiment;
    
    % Finish logging protocol
    cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end