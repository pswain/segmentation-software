function extractCellInformation(cExperiment,method)

%method is either 'overwrite' or 'update'. If overwrite, it goes through
%all of the cellsToPlot and extracts the information from the saved
%Timelapses. If method is 'update', it finds the cells that have been added
%to the cellsToPlot and adds their inf to the cellInf, and removes those
%that have been removed.

if nargin<2
    method='overwrite';
end
cExperiment.cellInf=struct;
numCells=sum(cExperiment.cellsToPlot(:));
cellLocs=[];
[cellLocs(:,1) cellLocs(:,2)]=find(cExperiment.cellsToPlot);
sizeCTP=size(cExperiment.cellsToPlot);
cTimelapse=cExperiment.returnTimelapse(1);
for i=1:numCells;

    cExperiment.cellInf(i).expPos=cellLocs(i,1);
    
    [cExperiment.cellInf(i).trap cExperiment.cellInf(i).cellNum]=ind2sub(sizeCTP(2:3),cellLocs(i,2));
    cExperiment.cellInf(i).extractedMean=zeros(1,length(cTimelapse.cTimepoint));
    cExperiment.cellInf(i).extractedMedian=zeros(1,length(cTimelapse.cTimepoint));
    cExperiment.cellInf(i).extractedMax5=zeros(1,length(cTimelapse.cTimepoint));
end

expPosToVisit=sort([cExperiment.cellInf.expPos]);
expPosToVisit=unique(expPosToVisit);
for i=1:length(expPosToVisit)
    expPos=expPosToVisit(i);
    disp(['Position Number ',int2str(expPos)]);
    cellsCurrPos=find([cExperiment.cellInf.expPos]==expPos);

    cTimelapse=cExperiment.returnTimelapse(expPos);
    cTimepoint=cTimelapse.cTimepoint;
    for timepoint=1:length(cTimelapse.cTimepoint)
%         disp(['Timepoint Number ',int2str(timepoint)]);
        traps=[cExperiment.cellInf(cellsCurrPos).trap];
        
        %modify below code to use the cExperiment.searchString rather
        %than just channel=2;
        trapImages=cTimelapse.returnTrapsTimepoint(traps,timepoint,2);
        %         trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
        trapInfo=cTimepoint(timepoint).trapInfo;
        for j=1:length(cellsCurrPos)
            currCell=cellsCurrPos(j);
            currTrap=traps(j);
            temp_loc=find(trapInfo(currTrap).cellLabel==cExperiment.cellInf(currCell).cellNum);
            if temp_loc
                trapIm=trapImages(:,:,j);
%                 cellArea=trapInfo(currTrap).segmented(:,:,temp_loc);
%                 cellCenter=trapInfo(currTrap).cellCenters(temp_loc,:);
                                cellArea=full(trapInfo(currTrap).cell(temp_loc).segmented);
                cellCenter=trapInfo(currTrap).cell(temp_loc).cellCenter;

                cellCenter=double(cellCenter);
                cellArea=imfill(cellArea,sub2ind(size(cellArea),cellCenter(2),cellCenter(1)));
                cellFL=trapIm(cellArea);
                
                %below is the function to extract the fluorescence information
                %from the cells. Change to mean/median FL etc
                flsorted=sort(cellFL(:),'descend');
                cExperiment.cellInf(currCell).extractedMax5(1,timepoint)=mean(flsorted(1:5));
                cExperiment.cellInf(currCell).extractedMean(1,timepoint)=mean(cellFL(:));
                cExperiment.cellInf(currCell).extractedMedian(1,timepoint)=median(cellFL(:));
                
            end
        end
        %         cTimelapse.cTimepoint(timepoint).trapInfo=trapInfo;
        cTimepoint(timepoint).trapInfo=trapInfo;
    end
    cTimelapse.cTimepoint=cTimepoint;
end

% 
% for i=1:numCells;
%     disp(['Cell Number ',int2str(i)]);
%     cTimelapse=cExperiment.returnTimelapse(cExperiment.cellInf(i).expPos);
%     cExperiment.cellInf(i).extractedInf=zeros(3,length(cTimelapse.cTimepoint));
%     locations=[];
%     for timepoint=1:length(cTimelapse.cTimepoint)
%         temp_loc=find(cTimelapse.cTimepoint(timepoint).trapInfo(cExperiment.cellInf(i).trap).cellLabel==cExperiment.cellInf(i).cellNum);
%         if temp_loc
%             %modify below code to use the cExperiment.searchString rather
%             %than just channel=2;
%             trapIm=cTimelapse.returnSingleTrapTimepoint(cExperiment.cellInf(i).trap,timepoint,2);
%             cellArea=cTimelapse.cTimepoint(timepoint).trapInfo(cExperiment.cellInf(i).trap).segmented(:,:,temp_loc);
%             cellCenter=cTimelapse.cTimepoint(timepoint).trapInfo(cExperiment.cellInf(i).trap).cellCenters(temp_loc,:);
%             cellCenter=double(cellCenter);
%             cellArea=imfill(cellArea,sub2ind(size(cellArea),cellCenter(2),cellCenter(1)));
%             cellFL=trapIm(cellArea);
%             
%             %below is the function to extract the fluorescence information
%             %from the cells. Change to mean/median FL etc
%             flsorted=sort(cellFL(:),'descend');
%             cExperiment.cellInf(i).extractedInf(1,timepoint)=mean(flsorted(1:5));
%             cExperiment.cellInf(i).extractedInf(2,timepoint)=mean(cellFL(:));
%             cExperiment.cellInf(i).extractedInf(3,timepoint)=median(cellFL(:));
%             
%         end
%     end
% end