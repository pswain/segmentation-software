function editTimelapse( cExperiment, cCellVision, positionsToIdentify)

if nargin<3
    positionsToIdentify=1:length(cExperiment.dirs);
end
    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load([cExperiment.saveFolder filesep cExperiment.dirs{currentPos},'cTimelapse']);
    cTrapDisplay(cTimelapse,cCellVision)
    
    uiwait();
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end



end

