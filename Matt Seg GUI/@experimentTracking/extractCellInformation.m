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

num_lines=1;
prompt = {'Extract all Params?'};
dlg_title = 'All Params';    def = {'1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

answer=str2num(answer{1});

%% Run the tracking on the timelapse
for i=1:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    %
    if answer
        cTimelapse.extractCellData();
    else
        cTimelapse.extractCellParamsOnly();
    end

    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end