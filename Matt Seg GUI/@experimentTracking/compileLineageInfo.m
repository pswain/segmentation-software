function compileLineageInfo(cExperiment,positionsToExtract)

%method is either 'overwrite' or 'update'. If overwrite, it goes through
%all of the cellsToPlot and extracts the information from the saved
%Timelapses. If method is 'update', it finds the cells that have been added
%to the cellsToPlot and adds their inf to the cellInf, and removes those
%that have been removed.



if nargin<2
    positionsToExtract=find(cExperiment.posTracked);
    %     positionsToTrack=1:length(cExperiment.dirs);
end

% cExperiment.lineageInfo.fitness=[];
cExperiment.lineageInfo.motherInfo.birthTime=[];
cExperiment.lineageInfo.motherInfo.birthRadius=[];
cExperiment.lineageInfo.motherInfo.daughterLabel=[];
cExperiment.lineageInfo.motherInfo.daughterTrapNum=[];
cExperiment.lineageInfo.motherInfo.motherStartEnd=[];
cExperiment.lineageInfo.motherInfo.motherPosNum=[];
cExperiment.lineageInfo.motherInfo.motherLabel=[];
cExperiment.lineageInfo.motherInfo.motherTrap=[];

for i=1:length(positionsToExtract)
    i
    experimentPos=positionsToExtract(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    
    %%
    if ~isempty(cTimelapse.lineageInfo)
        if ~isempty(cTimelapse.lineageInfo.motherInfo)
            t=cTimelapse.lineageInfo.motherInfo.birthTime;
            cExperiment.lineageInfo.motherInfo.birthTime(end+1:end+size(t,1),1:size(t,2))=t;
            
            t=cTimelapse.lineageInfo.motherInfo.birthRadius;
            cExperiment.lineageInfo.motherInfo.birthRadius(end+1:end+size(t,1),1:size(t,2))=t;
            
            t=cTimelapse.lineageInfo.motherInfo.daughterLabel;
            cExperiment.lineageInfo.motherInfo.daughterLabel(end+1:end+size(t,1),1:size(t,2))=t;
            
            t=cTimelapse.lineageInfo.motherInfo.daughterTrapNum;
            if ~isempty(t)
                cExperiment.lineageInfo.motherInfo.daughterTrapNum(end+1:end+size(t,1),1)=t(:,1);
            end
            
            t=cTimelapse.lineageInfo.motherInfo.motherStartEnd;
            cExperiment.lineageInfo.motherInfo.motherStartEnd(end+1:end+size(t,1),1:size(t,2))=t;
            
            t=ones(1,size(t,1))*experimentPos;
            cExperiment.lineageInfo.motherInfo.motherPosNum(end+1:end+length(t))=t;
            
            t=cTimelapse.lineageInfo.motherInfo.motherTrap;
            cExperiment.lineageInfo.motherInfo.motherTrap(end+1:end+length(t))=t;
            
            t=cTimelapse.lineageInfo.motherInfo.motherLabel;
            cExperiment.lineageInfo.motherInfo.motherLabel(end+1:end+length(t))=t;
        end
        
    end
    
    cExperiment.cTimelapse=[];
end
cExperiment.saveExperiment();
