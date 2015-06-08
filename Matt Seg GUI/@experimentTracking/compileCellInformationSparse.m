function compileCellInformationSparse(cExperiment,channel, positionsToExtract)

%method is either 'overwrite' or 'update'. If overwrite, it goes through
%all of the cellsToPlot and extracts the information from the saved
%Timelapses. If method is 'update', it finds the cells that have been added
%to the cellsToPlot and adds their inf to the cellInf, and removes those
%that have been removed.



if nargin<3
    positionsToExtract=find(cExperiment.posTracked);
    %     positionsToTrack=1:length(cExperiment.dirs);
end

%% Run the tracking on the timelapse
experimentPos=positionsToExtract(1);
load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
cExperiment.cellInf=struct(cTimelapse.extractedData);
% [cExperiment.cellInf(:).posNum]=[];
[cExperiment.cellInf(:).posNum]=deal(repmat(1,[size(cExperiment.cellInf(1).trapNum)]));

tempLen=50e3;
for i=channel
    cExperiment.cellInf(i).mean=sparse(tempLen,size(cExperiment.cellInf(i).mean,2));
    cExperiment.cellInf(i).median=sparse(tempLen,size(cExperiment.cellInf(i).median,2));
    cExperiment.cellInf(i).max5=sparse(tempLen,size(cExperiment.cellInf(i).max5,2));
    cExperiment.cellInf(i).std=sparse(tempLen,size(cExperiment.cellInf(i).std,2));
    %     cExperiment.cellInf(i).smallmean=sparse(tempLen,size(cExperiment.cellInf(i).smallmean,2));
    %     cExperiment.cellInf(i).smallmedian=sparse(tempLen,size(cExperiment.cellInf(i).smallmedian,2));
    %     cExperiment.cellInf(i).smallmax5=sparse(tempLen,size(cExperiment.cellInf(i).smallmax5,2));
    cExperiment.cellInf(i).min=sparse(tempLen,size(cExperiment.cellInf(i).min,2));
    cExperiment.cellInf(i).imBackground=sparse(tempLen,size(cExperiment.cellInf(i).imBackground,2));
    cExperiment.cellInf(i).radius=sparse(tempLen,size(cExperiment.cellInf(i).radius,2));
    cExperiment.cellInf(i).xloc=sparse(tempLen,size(cExperiment.cellInf(i).xloc,2));
    cExperiment.cellInf(i).yloc=sparse(tempLen,size(cExperiment.cellInf(i).yloc,2));
    cExperiment.cellInf(i).area=sparse(tempLen,size(cExperiment.cellInf(i).area,2));
    
    %     cExperiment.cellInf(i).membraneMedian= sparse(tempLen,size(cExperiment.cellInf(i).membraneMedian,2));
    %     cExperiment.cellInf(i).membraneMax5= sparse(tempLen,size(cExperiment.cellInf(i).membraneMax5,2));
    
    
end

index=0;
for i=1:length(positionsToExtract)
    i
    experimentPos=positionsToExtract(i);
    %     load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse=cExperiment.returnTimelapse(experimentPos);
    dim=1;
    if max(cTimelapse.timepointsProcessed)>0
        for j=channel
            temp=cTimelapse.extractedData(j).mean;
            cExperiment.cellInf(j).mean(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).median;
            cExperiment.cellInf(j).median(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).max5;
            cExperiment.cellInf(j).max5(index+1:index+size(temp,1),1:size(temp,2))=temp;
            %             temp=cTimelapse.extractedData(j).std;
            %             cExperiment.cellInf(j).std(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            %             temp=cTimelapse.extractedData(j).smallmean;
            %             cExperiment.cellInf(j).smallmean(index+1:index+size(temp,1),1:size(temp,2))=temp;
            %             temp=cTimelapse.extractedData(j).smallmedian;
            %             cExperiment.cellInf(j).smallmedian(index+1:index+size(temp,1),1:size(temp,2))=temp;
            %             temp=cTimelapse.extractedData(j).smallmax5;
            %             cExperiment.cellInf(j).smallmax5(index+1:index+size(temp,1),1:size(temp,2))=temp;
            %
            %             temp=cTimelapse.extractedData(j).membraneMedian;
            %             cExperiment.cellInf(j).membraneMedian(index+1:index+size(temp,1),1:size(temp,2))=temp;
            %             temp=cTimelapse.extractedData(j).membraneMax5;
            %             cExperiment.cellInf(j).membraneMax5(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            %             temp=cTimelapse.extractedData(j).imBackground;
            %             cExperiment.cellInf(j).imBackground(index+1:index+size(temp,1),1:size(temp,2))=temp;
            %             temp=cTimelapse.extractedData(j).min;
            %             cExperiment.cellInf(j).min(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            temp=cTimelapse.extractedData(j).radius;
            cExperiment.cellInf(j).radius(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            temp=cTimelapse.extractedData(j).xloc;
            cExperiment.cellInf(j).xloc(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).yloc;
            cExperiment.cellInf(j).yloc(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            temp=cTimelapse.extractedData(j).trapNum;
            cExperiment.cellInf(j).trapNum(index+1:index+length(temp))=temp;
            temp=cTimelapse.extractedData(j).cellNum;
            cExperiment.cellInf(j).cellNum(index+1:index+length(temp))=temp;
            
            cExperiment.cellInf(j).posNum(index+1:index+length(temp))=experimentPos;
        end
        index=index+size(cTimelapse.extractedData(j).xloc,1);
    end
    cExperiment.cTimelapse=[];
    cExperiment.saveExperiment();
    
end

for i=1:length(cExperiment.cellInf)
    cExperiment.cellInf(i).mean(index+1:end,:)=[];
    cExperiment.cellInf(i).median(index+1:end,:)=[];
    cExperiment.cellInf(i).max5(index+1:end,:)=[];
    cExperiment.cellInf(i).std(index+1:end,:)=[];
    %     cExperiment.cellInf(i).smallmean(index+1:end,:)=[];
    %     cExperiment.cellInf(i).smallmedian(index+1:end,:)=[];
    %     cExperiment.cellInf(i).smallmax5(index+1:end,:)=[];
    cExperiment.cellInf(i).min(index+1:end,:)=[];
    cExperiment.cellInf(i).imBackground(index+1:end,:)=[];
    
    %     cExperiment.cellInf(i).membraneMedian(index+1:end,:)=[];
    %     cExperiment.cellInf(i).membraneMax5(index+1:end,:)=[];
    
    
    cExperiment.cellInf(i).radius(index+1:end,:)=[];
    cExperiment.cellInf(i).xloc(index+1:end,:)=[];
    cExperiment.cellInf(i).yloc(index+1:end,:)=[];
    
    cExperiment.cellInf(i).area(index+1:end,:)=[];
end

cExperiment.saveExperiment();
