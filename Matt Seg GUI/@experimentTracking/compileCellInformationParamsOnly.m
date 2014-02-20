function compileCellInformationParamsOnly(cExperiment,positionsToExtract)

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
experimentPos=positionsToExtract(1);
load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
cExperiment.cellInf=struct(cTimelapse.extractedData);
% [cExperiment.cellInf(:).posNum]=[];
[cExperiment.cellInf(:).posNum]=deal(repmat(1,[size(cExperiment.cellInf(1).trapNum)]));
for i=2:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    
    if max(cTimelapse.timepointsProcessed)>0
        if ~isempty(cTimelapse.extractedData(1).radius)
            j=1;
                
                temp=cTimelapse.extractedData(j).radius;
                cExperiment.cellInf(j).radius(end+1:end+size(temp,1),:)=temp;
                temp=cTimelapse.extractedData(j).trapNum;
                cExperiment.cellInf(j).trapNum(end+1:end+size(temp,1),:)=temp;
                temp=cTimelapse.extractedData(j).cellNum;
                cExperiment.cellInf(j).cellNum(end+1:end+size(temp,1),:)=temp;
                
                temp=cTimelapse.extractedData(j).xloc;
                cExperiment.cellInf(j).xloc(end+1:end+size(temp,1),:)=temp;
                temp=cTimelapse.extractedData(j).yloc;
                cExperiment.cellInf(j).yloc(end+1:end+size(temp,1),:)=temp;
                
                
                cExperiment.cellInf(j).posNum(end+1:end+size(temp,1),:)=experimentPos;
        end
    end
    cExperiment.cTimelapse=[];
end
cExperiment.saveExperiment();