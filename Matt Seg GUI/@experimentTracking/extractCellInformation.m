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
prompt = {'What do you want to extract?'};
dlg_title = 'All Params using max projection (max), std focus (std), mean focus (mean), or basic (basic)';    def = {'max'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

type=answer{1};

%% Run the tracking on the timelapse
for i=1:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    %
    switch type
        case {'max','all','std'} 
            cTimelapse.extractCellData(type);
        case {'b','basic'}
            cTimelapse.extractCellParamsOnly();
    end

    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end