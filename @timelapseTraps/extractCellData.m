function extractCellData(cTimelapse)

numCells=sum(cTimelapse.cellsToPlot(:));
[trap cell]=find(cTimelapse.cellsToPlot);

s1=strel('disk',1);
% convMatrix2=single(getnhood(strel('disk',2)));


if isempty(cTimelapse.timepointsProcessed) || length(cTimelapse.timepointsProcessed)==1
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
    if length(cTimelapse.timepointsProcessed)==1
        cTimelapse.timepointsProcessed=0;
    end
end


for channel=1:length(cTimelapse.channelNames)
    cTimelapse.extractedData(channel).mean=zeros(numCells,length(cTimelapse.timepointsProcessed));
    cTimelapse.extractedData(channel).median=zeros(numCells,length(cTimelapse.timepointsProcessed));
    cTimelapse.extractedData(channel).max5=zeros(numCells,length(cTimelapse.timepointsProcessed));
    cTimelapse.extractedData(channel).std=zeros(numCells,length(cTimelapse.timepointsProcessed));
    
    cTimelapse.extractedData(channel).smallmean=zeros(numCells,length(cTimelapse.timepointsProcessed));
    cTimelapse.extractedData(channel).smallmedian=zeros(numCells,length(cTimelapse.timepointsProcessed));
    cTimelapse.extractedData(channel).smallmax5=zeros(numCells,length(cTimelapse.timepointsProcessed));
    cTimelapse.extractedData(channel).min=zeros(numCells,length(cTimelapse.timepointsProcessed));
    cTimelapse.extractedData(channel).imBackground=zeros(numCells,length(cTimelapse.timepointsProcessed));

    
    cTimelapse.extractedData(channel).radius=zeros(numCells,length(cTimelapse.timepointsProcessed));
    
    cTimelapse.extractedData(channel).trapNum=trap;
    cTimelapse.extractedData(channel).cellNum=cell;
    
    for timepoint=1:length(cTimelapse.timepointsProcessed)
        if cTimelapse.timepointsProcessed(timepoint)
            disp(['Timepoint Number ',int2str(timepoint)]);
            traps=[cTimelapse.extractedData(channel).trapNum];
            %     uniqueTraps=unique(traps);
            %modify below code to use the cExperiment.searchString rather
            %than just channel=2;
            
            trapImages=cTimelapse.returnTrapsTimepoint(traps,timepoint,channel);
            trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
            for j=1:length(cTimelapse.extractedData(channel).cellNum)
                currCell=cTimelapse.extractedData(channel).cellNum(j);
                currTrap=cTimelapse.extractedData(channel).trapNum(j);
                
                temp_loc=find(trapInfo(currTrap).cellLabel==currCell);
                if temp_loc
                    if cTimelapse.trapsPresent
                        trapIm=trapImages(:,:,j);
                    else
                        trapIm=trapImages;
                    end
                    
                    
                    
                    seg_areas=full(trapInfo(currTrap).cell(temp_loc).segmented);
                    segLabel=zeros(size(seg_areas));
                    loc=double(cTimelapse.cTimepoint(timepoint).trapInfo(trap(j)).cell(temp_loc).cellCenter);
                    if ~isempty(loc)
                        segLabel=imfill(seg_areas(:,:,1),sub2ind(size(seg_areas(:,:,1)),loc(2),loc(1)));
                    end
                    
                    
                    
                    %                 temp_im=trapInfo(currTrap).trackLabel==currCell;
                    cellLoc=segLabel>0;
                    cellFL=trapIm(cellLoc);
                    
                    %below is the function to extract the fluorescence information
                    %from the cells. Change to mean/median FL etc
                    flsorted=sort(cellFL(:),'descend');
                    convMatrix=zeros(3,3);
                    convMatrix(2,:)=1;convMatrix(:,2)=1;
                    %                 flPeak=conv2(single(trapIm),convMatrix);
                    %                 flPeak=flPeak(cellLoc);
                    
                    cTimelapse.extractedData(channel).max5(j,timepoint)=mean(flsorted(1:5));
                    cTimelapse.extractedData(channel).mean(j,timepoint)=mean(cellFL(:));
                    cTimelapse.extractedData(channel).median(j,timepoint)=median(cellFL(:));
                    
                    cellLocSmall=imerode(cellLoc,s1);
                    if sum(cellLocSmall)<1
                    end
                    
                    cellFLsmall=trapIm(cellLocSmall);
                    flPeak=conv2(double(trapIm),convMatrix);
                    flPeak=flPeak(cellLoc);
                    
                    cTimelapse.extractedData(channel).smallmax5(j,timepoint)=max(flPeak(:));
                    cTimelapse.extractedData(channel).smallmean(j,timepoint)=mean(cellFLsmall(:));
                    cTimelapse.extractedData(channel).smallmedian(j,timepoint)=median(cellFLsmall(:));
                    
                    seg_areas=zeros(size(trapInfo(currTrap).cell(1).segmented));
                    for allCells=1:length(trapInfo(currTrap).cellLabel)
                        seg_areas=seg_areas|full(trapInfo(currTrap).cell(allCells).segmented);
%                         seg_areas=imdilate(seg_areas,s1);
                        loc=double(cTimelapse.cTimepoint(timepoint).trapInfo(trap(j)).cell(allCells).cellCenter);
                        if ~isempty(loc)
                            seg_areas=imfill(seg_areas(:,:,1),sub2ind(size(seg_areas(:,:,1)),loc(2),loc(1)));
                        end
                    end
                    seg_areas=~seg_areas;
                    
                    bkg=trapIm(seg_areas);
                    cTimelapse.extractedData(channel).std(j,timepoint)=std(double(cellFL(:)));
                    cTimelapse.extractedData(channel).imBackground(j,timepoint)=median(bkg(:));
                    cTimelapse.extractedData(channel).min(j,timepoint)=min(cellFL(:));
                    
                    cTimelapse.extractedData(channel).radius(j,timepoint)=trapInfo(currTrap).cell(temp_loc).cellRadius;
                    
                end
            end
        end
    end
end