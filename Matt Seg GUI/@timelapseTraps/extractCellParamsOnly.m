function extractCellParamsOnly(cTimelapse)

numCells=sum(cTimelapse.cellsToPlot(:));
[trap cell]=find(cTimelapse.cellsToPlot);

s1=strel('disk',2);
% convMatrix2=single(getnhood(strel('disk',2)));


if isempty(cTimelapse.timepointsProcessed) || length(cTimelapse.timepointsProcessed)==1
    tempSize=[cTimelapse.cTimepoint.trapInfo];
    cTimelapse.timepointsProcessed=ones(1,length(tempSize)/length(cTimelapse.cTimepoint(1).trapInfo));
    if length(cTimelapse.timepointsProcessed)==1
        cTimelapse.timepointsProcessed=0;
    end
end


for channel=1:1%length(cTimelapse.channelNames)
    extractedData(channel).mean=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).median=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).max5=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).std=sparse(numCells,length(cTimelapse.timepointsToProcess));
    
    extractedData(channel).smallmean=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).smallmedian=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).smallmax5=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).min=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).imBackground=sparse(numCells,length(cTimelapse.timepointsToProcess));

    extractedData(channel).distToNuc=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).nucArea=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).radius=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).radiusAC=sparse(zeros(numCells,length(cTimelapse.timepointsProcessed)));
    extractedData(channel).xloc=sparse(numCells,length(cTimelapse.timepointsToProcess));
    extractedData(channel).yloc=sparse(numCells,length(cTimelapse.timepointsToProcess));
    
    extractedData(channel).trapNum=trap;
    extractedData(channel).cellNum=cell;
    
    for timepoint=1:length(cTimelapse.timepointsToProcess)
        if cTimelapse.timepointsProcessed(timepoint)
            disp(['Timepoint Number ',int2str(timepoint)]);
            %modify below code to use the cExperiment.searchString rather
            %than just channel=2;
            
            trapInfo=cTimelapse.cTimepoint(timepoint).trapInfo;
            for j=1:length(extractedData(channel).cellNum)
                currCell=extractedData(channel).cellNum(j);
                currTrap=extractedData(channel).trapNum(j);
                
                temp_loc=find(trapInfo(currTrap).cellLabel==currCell);
                if temp_loc 
                    extractedData(channel).radius(j,timepoint)=trapInfo(currTrap).cell(temp_loc).cellRadius;
                    extractedData(channel).xloc(j,timepoint)=trapInfo(currTrap).cell(temp_loc).cellCenter(1);
                    extractedData(channel).yloc(j,timepoint)=trapInfo(currTrap).cell(temp_loc).cellCenter(2);

                    if isfield(trapInfo(currTrap).cell(temp_loc),'nucArea');
                        if isempty(trapInfo(currTrap).cell(temp_loc).nucArea)
                            extractedData(channel).nucArea(j,timepoint)=NaN;
                            extractedData(channel).distToNuc(j,timepoint)=NaN;
                        else
                            extractedData(channel).nucArea(j,timepoint)=trapInfo(currTrap).cell(temp_loc).nucArea;
                            extractedData(channel).distToNuc(j,timepoint)=trapInfo(currTrap).cell(temp_loc).distToNuc;
                        end
                    end
                    if isfield(trapInfo(currTrap).cell(temp_loc),'radiusAC');
                        extractedData(channel).radiusAC(j,timepoint)=trapInfo(currTrap).cell(temp_loc).radiusAC;
                    end
                end
            end
        end
    end
end
cTimelapse.extractedData=extractedData;