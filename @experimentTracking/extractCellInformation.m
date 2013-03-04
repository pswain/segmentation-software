function extractCellInformation(cExperiment,positionsToExtract)

%method is either 'overwrite' or 'update'. If overwrite, it goes through
%all of the cellsToPlot and extracts the information from the saved
%Timelapses. If method is 'update', it finds the cells that have been added
%to the cellsToPlot and adds their inf to the cellInf, and removes those
%that have been removed.



if nargin<2
    positionsToExtract=find(cExperiment.posTracked);
%     positionsToTrack=1:length(cExperiment.dirs);
end

%% Run the tracking on the timelapse
for i=1:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse.extractCellData();
    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end