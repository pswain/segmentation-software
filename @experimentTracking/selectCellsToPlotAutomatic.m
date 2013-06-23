function selectCellsToPlotAutomatic(cExperiment,positionsToCheck,params)
if nargin<2
    positionsToCheck=find(cExperiment.posTracked);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3
    params.fraction=.8; %fraction of timelapse length that cells must be present or
    params.duration=40; %number of frames cells must be present
%     params.cellsToCheck=4;
    params.framesToCheck=160;
end


%% Run the tracking on the timelapse
for i=1:length(positionsToCheck)
    experimentPos=positionsToCheck(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse.automaticSelectCells(params);
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end