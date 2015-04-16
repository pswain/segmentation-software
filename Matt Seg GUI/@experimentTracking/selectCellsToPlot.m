function selectCellsToPlot(cExperiment,cCellVision,positionsToIdentify,channel)

if nargin<3 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end
   
if nargin<4 || isempty(channel)
    channel =1;
end

%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    fprintf('selecting cells for position %s\n',cExperiment.dirs{currentPos})
    load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cTrapDisplayPlot(cTimelapse,cCellVision,[],channel);
    
    uiwait();
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
