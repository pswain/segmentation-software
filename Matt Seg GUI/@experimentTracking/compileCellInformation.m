function compileCellInformation(cExperiment,positionsToExtract)
%compileCellInformation(cExperiment,positionsToExtract)
%
%method is either 'overwrite' or 'update'. If overwrite, it goes through
%all of the cellsToPlot and extracts the information from the saved
%Timelapses. If method is 'update', it finds the cells that have been added
%to the cellsToPlot and adds their inf to the cellInf, and removes those
%that have been removed.



if nargin<2
    %positionsToExtract=find(cExperiment.posTracked);
         positionsToExtract=1:length(cExperiment.dirs);
end

%% Run the tracking on the timelapse
experimentPos=positionsToExtract(1);
cTimelapse=cExperiment.returnTimelapse(experimentPos);
%load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
cExperiment.cellInf=struct(cTimelapse.extractedData);
% [cExperiment.cellInf(:).posNum]=[];
[cExperiment.cellInf(:).posNum]=deal(ones(size(cExperiment.cellInf(1).trapNum)));

% %%alternative if anyone ever wants to implement it
% 
% for i=1:length(cExperiment.cellInf)
%     field_names = fieldnames(cExperiment.cellInf);
%     for fi = 1:length(field_names)
%         fn = field_names{fi};
%         cExperiment.cellInf(i).(fn)=sparse(tempLen,size(cExperiment.cellInf(i).(fn),2));
%     end
% end
% 
% %then similarly over positions to compile
% %Elco


tempLen=50e3;
membraneData=isfield(cExperiment.cellInf(1),'membraneMedian');
radiusFLData=isfield(cExperiment.cellInf(1),'radiusFL');
segmentedRadiusData=isfield(cExperiment.cellInf(1),'segmentedRadius');
radiusACData=isfield(cExperiment.cellInf(1),'radiusAC');
nucAreaData=isfield(cExperiment.cellInf(1),'nucArea');


for i=1:length(cExperiment.cellInf)
    cExperiment.cellInf(i).mean=sparse(tempLen,size(cExperiment.cellInf(i).mean,2));
    cExperiment.cellInf(i).median=sparse(tempLen,size(cExperiment.cellInf(i).median,2));
    cExperiment.cellInf(i).max5=sparse(tempLen,size(cExperiment.cellInf(i).max5,2));
    cExperiment.cellInf(i).std=sparse(tempLen,size(cExperiment.cellInf(i).std,2));
    cExperiment.cellInf(i).smallmean=sparse(tempLen,size(cExperiment.cellInf(i).smallmean,2));
    cExperiment.cellInf(i).smallmedian=sparse(tempLen,size(cExperiment.cellInf(i).smallmedian,2));
    cExperiment.cellInf(i).smallmax5=sparse(tempLen,size(cExperiment.cellInf(i).smallmax5,2));
    cExperiment.cellInf(i).min=sparse(tempLen,size(cExperiment.cellInf(i).min,2));
    cExperiment.cellInf(i).imBackground=sparse(tempLen,size(cExperiment.cellInf(i).imBackground,2));    
    cExperiment.cellInf(i).radius=sparse(tempLen,size(cExperiment.cellInf(i).radius,2));

   
    cExperiment.cellInf(i).xloc=sparse(tempLen,size(cExperiment.cellInf(i).xloc,2));
    cExperiment.cellInf(i).yloc=sparse(tempLen,size(cExperiment.cellInf(i).yloc,2));
    cExperiment.cellInf(i).area=sparse(tempLen,size(cExperiment.cellInf(i).area,2));
    cExperiment.cellInf(i).pixel_sum= sparse(tempLen,size(cExperiment.cellInf(i).pixel_sum,2));
    cExperiment.cellInf(i).pixel_variance_estimate= sparse(tempLen,size(cExperiment.cellInf(i).pixel_variance_estimate,2));

    if membraneData
        cExperiment.cellInf(i).membraneMedian= sparse(tempLen,size(cExperiment.cellInf(i).membraneMedian,2));
        cExperiment.cellInf(i).membraneMax5= sparse(tempLen,size(cExperiment.cellInf(i).membraneMax5,2));
        cExperiment.cellInf(i).nuclearTagLoc= sparse(tempLen,size(cExperiment.cellInf(i).nuclearTagLoc,2));
    end
    
    if radiusFLData
        cExperiment.cellInf(i).radiusFL= sparse(tempLen,size(cExperiment.cellInf(i).radiusFL,2));
    end
    

    if segmentedRadiusData
        cExperiment.cellInf(i).segmentedRadius= sparse(tempLen,size(cExperiment.cellInf(i).segmentedRadius,2));
    end
    
    if radiusACData
        cExperiment.cellInf(i).radiusAC= sparse(tempLen,size(cExperiment.cellInf(i).radiusAC,2));
    end
    
    if nucAreaData
        cExperiment.cellInf(i).nucArea= sparse(tempLen,size(cExperiment.cellInf(i).nucArea,2));
        cExperiment.cellInf(i).distToNuc= sparse(tempLen,size(cExperiment.cellInf(i).distToNuc,2));
    end

% 
%     cExperiment.cellInf(i).mean=zeros(tempLen,size(cExperiment.cellInf(i).mean,2),size(cExperiment.cellInf(i).mean,3));
%     cExperiment.cellInf(i).median=zeros(tempLen,size(cExperiment.cellInf(i).median,2),size(cExperiment.cellInf(i).median,3));
%     cExperiment.cellInf(i).max5=zeros(tempLen,size(cExperiment.cellInf(i).max5,2),size(cExperiment.cellInf(i).max5,3));
%     cExperiment.cellInf(i).std=zeros(tempLen,size(cExperiment.cellInf(i).std,2),size(cExperiment.cellInf(i).std,3));
%     cExperiment.cellInf(i).smallmean=zeros(tempLen,size(cExperiment.cellInf(i).smallmean,2),size(cExperiment.cellInf(i).smallmean,3));
%     cExperiment.cellInf(i).smallmedian=zeros(tempLen,size(cExperiment.cellInf(i).smallmedian,2),size(cExperiment.cellInf(i).smallmedian,3));
%     cExperiment.cellInf(i).smallmax5=zeros(tempLen,size(cExperiment.cellInf(i).smallmax5,2),size(cExperiment.cellInf(i).smallmax5,3));
%     cExperiment.cellInf(i).min=zeros(tempLen,size(cExperiment.cellInf(i).min,2),size(cExperiment.cellInf(i).min,3));
%     cExperiment.cellInf(i).imBackground=zeros(tempLen,size(cExperiment.cellInf(i).imBackground,2),size(cExperiment.cellInf(i).imBackground,3));    
%     cExperiment.cellInf(i).radius=zeros(tempLen,size(cExperiment.cellInf(i).radius,2),size(cExperiment.cellInf(i).radius,3));
%     cExperiment.cellInf(i).xloc=zeros(tempLen,size(cExperiment.cellInf(i).xloc,2),size(cExperiment.cellInf(i).xloc,3));
%     cExperiment.cellInf(i).yloc=zeros(tempLen,size(cExperiment.cellInf(i).yloc,2),size(cExperiment.cellInf(i).yloc,3));
%     cExperiment.cellInf(i).area=zeros(tempLen,size(cExperiment.cellInf(i).area,2),size(cExperiment.cellInf(i).area,3));

end

index=0;
for i=1:length(positionsToExtract)
    i
    experimentPos=positionsToExtract(i);
%     load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse=cExperiment.returnTimelapse(experimentPos);
    dim=1;
    if max(cTimelapse.timepointsProcessed)>0
        for j=1:length(cTimelapse.extractedData)
            temp=cTimelapse.extractedData(j).mean;
            cExperiment.cellInf(j).mean(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).median;
            cExperiment.cellInf(j).median(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).max5;
            cExperiment.cellInf(j).max5(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).std;
            cExperiment.cellInf(j).std(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            temp=cTimelapse.extractedData(j).smallmean;
            cExperiment.cellInf(j).smallmean(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).smallmedian;
            cExperiment.cellInf(j).smallmedian(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).smallmax5;
            cExperiment.cellInf(j).smallmax5(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            if membraneData
                temp=cTimelapse.extractedData(j).membraneMedian;
                cExperiment.cellInf(j).membraneMedian(index+1:index+size(temp,1),1:size(temp,2))=temp;
                
                temp=cTimelapse.extractedData(j).membraneMax5;
                cExperiment.cellInf(j).membraneMax5(index+1:index+size(temp,1),1:size(temp,2))=temp;
                
                temp=cTimelapse.extractedData(j).nuclearTagLoc;
                cExperiment.cellInf(j).nuclearTagLoc(index+1:index+size(temp,1),1:size(temp,2))=temp;
            end
            
            
            if radiusFLData
                temp=cTimelapse.extractedData(j).radiusFL;
                cExperiment.cellInf(j).radiusFL(index+1:index+size(temp,1),1:size(temp,2))=temp;
            end
            if radiusACData
                temp=cTimelapse.extractedData(j).radiusAC;
                cExperiment.cellInf(j).radiusAC(index+1:index+size(temp,1),1:size(temp,2))=temp;
            end
            
            if nucAreaData
                temp=cTimelapse.extractedData(j).nucArea;
                cExperiment.cellInf(j).nucArea(index+1:index+size(temp,1),1:size(temp,2))=temp;
                temp=cTimelapse.extractedData(j).distToNuc;
                cExperiment.cellInf(j).distToNuc(index+1:index+size(temp,1),1:size(temp,2))=temp;

            end

            
            if segmentedRadiusData
                temp=cTimelapse.extractedData(j).segmentedRadius;
                cExperiment.cellInf(j).segmentedRadius(index+1:index+size(temp,1),1:size(temp,2))=temp;
            end

            
            temp=cTimelapse.extractedData(j).imBackground;
            cExperiment.cellInf(j).imBackground(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).min;
            cExperiment.cellInf(j).min(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            temp=cTimelapse.extractedData(j).radius;
            cExperiment.cellInf(j).radius(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).xloc;
            cExperiment.cellInf(j).xloc(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).yloc;
            cExperiment.cellInf(j).yloc(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            temp=cTimelapse.extractedData(j).trapNum;
            cExperiment.cellInf(j).trapNum(index+1:index+size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).cellNum;
            cExperiment.cellInf(j).cellNum(index+1:index+size(temp,2))=temp;
            
            
            temp=cTimelapse.extractedData(j).pixel_sum;
            cExperiment.cellInf(j).pixel_sum(index+1:index+size(temp,1),1:size(temp,2))=temp;
            temp=cTimelapse.extractedData(j).pixel_variance_estimate;
            cExperiment.cellInf(j).pixel_variance_estimate(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            temp=cTimelapse.extractedData(j).area;
            cExperiment.cellInf(j).area(index+1:index+size(temp,1),1:size(temp,2))=temp;
            
            
            cExperiment.cellInf(j).posNum(index+1:index+size(temp,1))=experimentPos;
        end
        index=index+size(cTimelapse.extractedData(j).xloc,1);
    end
    cExperiment.cTimelapse=[];
end

for i=1:length(cExperiment.cellInf)
    cExperiment.cellInf(i).mean(index+1:end,:)=[];
    cExperiment.cellInf(i).median(index+1:end,:)=[];
    cExperiment.cellInf(i).max5(index+1:end,:)=[];
    cExperiment.cellInf(i).std(index+1:end,:)=[];
    cExperiment.cellInf(i).smallmean(index+1:end,:)=[];
    cExperiment.cellInf(i).smallmedian(index+1:end,:)=[];
    cExperiment.cellInf(i).smallmax5(index+1:end,:)=[];
    cExperiment.cellInf(i).min(index+1:end,:)=[];
    cExperiment.cellInf(i).imBackground(index+1:end,:)=[];
    
    if membraneData
        cExperiment.cellInf(i).membraneMedian(index+1:end,:)=[];
        cExperiment.cellInf(i).membraneMax5(index+1:end,:)=[];
        cExperiment.cellInf(i).nuclearTagLoc(index+1:end,:)=[];
    end
    
    if radiusFLData
        cExperiment.cellInf(i).radiusFL(index+1:end,:)=[];
    end
    
    if segmentedRadiusData
        cExperiment.cellInf(i).segmentedRadius(index+1:end,:)=[];
    end
    
    if radiusACData
    cExperiment.cellInf(i).radiusAC(index+1:end,:)=[];
    end
    
    if nucAreaData
        cExperiment.cellInf(i).nucArea(index+1:end,:)=[];
        cExperiment.cellInf(i).distToNuc(index+1:end,:)=[];
    end

    cExperiment.cellInf(i).radius(index+1:end,:)=[];
    cExperiment.cellInf(i).xloc(index+1:end,:)=[];
    cExperiment.cellInf(i).yloc(index+1:end,:)=[];
    
    cExperiment.cellInf(i).area(index+1:end,:)=[];
    cExperiment.cellInf(i).pixel_sum(index+1:end,:)=[];
    cExperiment.cellInf(i).pixel_variance_estimate(index+1:end,:)=[];
    cExperiment.cellInf(i).area(index+1:end,:)=[];
end

cExperiment.saveExperiment();
