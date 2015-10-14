function createTimelapsePositions(cExperiment,searchString,positionsToLoad,pixelSize,image_rotation,timepointsToLoad)

%cExperiment.OmeroDatabase is empty when using a dataset from a file folder
if ~isempty(cExperiment.OmeroDatabase)
    oImages=cExperiment.omeroDs.linkedImageList;
end



if ~isempty(cExperiment.OmeroDatabase)
    chNames=cExperiment.OmeroDatabase.Channels;
    ch = menu('Choose channel used in segmentation (brightfield/DIC images)',cExperiment.OmeroDatabase.Channels);
    searchString=chNames{ch};
else
    if nargin<2 || isempty(searchString)
        searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'DIC'});
    end
end

if ~isempty(cExperiment.OmeroDatabase)
    positionsToLoad=1:oImages.size;
else
    if nargin<3 || strcmp(positionsToLoad,'all')
        positionsToLoad=1:length(cExperiment.dirs);
    end
end
    
if nargin<4
    pixelSize=[];
end

if nargin<5
    image_rotation=[];
end

if nargin<6
    timepointsToLoad=[];
end

cExperiment.searchString=searchString;
cExperiment.pixelSize=pixelSize;
cExperiment.image_rotation=image_rotation;
cExperiment.timepointsToLoad=timepointsToLoad;

traps_present = [];
%% Load timelapses
for i=1:length(positionsToLoad)
    currentPos=positionsToLoad(i);
    if ~isempty(cExperiment.OmeroDatabase)
        cExperiment.cTimelapse=timelapseTraps(oImages.get(i-1),cExperiment.OmeroDatabase);
    else
        cExperiment.cTimelapse=timelapseTraps([cExperiment.rootFolder filesep cExperiment.dirs{currentPos}]);
    end
    cExperiment.cTimelapse.loadTimelapse(cExperiment.searchString,cExperiment.magnification,cExperiment.image_rotation,traps_present,cExperiment.timepointsToLoad,cExperiment.imScale);
    cExperiment.magnification=cExperiment.cTimelapse.magnification;
    cExperiment.imScale=cExperiment.cTimelapse.imScale;

    cExperiment.image_rotation=cExperiment.cTimelapse.image_rotation;
    cExperiment.searchString=cExperiment.cTimelapse.channelNames;
    %cExperiment.timepointsToLoad=length(cExperiment.cTimelapse.cTimepoint);
    traps_present = cExperiment.cTimelapse.trapsPresent;
    cExperiment.timepointsToProcess = cExperiment.cTimelapse.timepointsToProcess;
    
    cExperiment.saveTimelapseExperiment(currentPos,false);%The false input tells this function no to save the cExperiment each time. Will speed it up a bit
end
%Set timepointsToProcess - should be the smallest one of the timelapses