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
    extractedData(channel).mean=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).median=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).max5=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).std=zeros(numCells,length(cTimelapse.timepointsProcessed));
    
    extractedData(channel).smallmean=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).smallmedian=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).smallmax5=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).min=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).imBackground=zeros(numCells,length(cTimelapse.timepointsProcessed));

    
    extractedData(channel).radius=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).xloc=zeros(numCells,length(cTimelapse.timepointsProcessed));
    extractedData(channel).yloc=zeros(numCells,length(cTimelapse.timepointsProcessed));
    
    extractedData(channel).trapNum=trap;
    extractedData(channel).cellNum=cell;
    
    for timepoint=1:length(cTimelapse.timepointsProcessed)
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

                    
                end
            end
        end
    end
end
cTimelapse.extractedData=extractedData;