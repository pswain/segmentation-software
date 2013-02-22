function extractCellData(cTimelapse,channel)

numCells=sum(cTimelapse.cellsToPlot(:));
[trap cell]=find(cTimelapse.cellsToPlot);

cTimelapse.extractedData(channel).mean=zeros(numCells,length(cTimelapse.cTimepoint));
cTimelapse.extractedData(channel).median=zeros(numCells,length(cTimelapse.cTimepoint));
cTimelapse.extractedData(channel).max5=zeros(numCells,length(cTimelapse.cTimepoint));
cTimelapse.extractedData(channel).std=zeros(numCells,length(cTimelapse.cTimepoint));

cTimelapse.extractedData(channel).radius=zeros(numCells,length(cTimelapse.cTimepoint));

cTimelapse.extractedData(channel).trapNum=trap;
cTimelapse.extractedData(channel).cellNum=cell;

for timepoint=1:length(cTimelapse.cTimepoint)
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
            trapIm=trapImages(:,:,j);
            temp_im=trapInfo(currTrap).trackLabel==currCell;
            
%             cellArea=full(temp_im);
            cellFL=trapIm(temp_im);
            
            %below is the function to extract the fluorescence information
            %from the cells. Change to mean/median FL etc
            flsorted=sort(cellFL(:),'descend');
            cTimelapse.extractedData(channel).max5(j,timepoint)=mean(flsorted(1:5));
            cTimelapse.extractedData(channel).mean(j,timepoint)=mean(cellFL(:));
            cTimelapse.extractedData(channel).median(j,timepoint)=median(cellFL(:));
            cTimelapse.extractedData(channel).std(j,timepoint)=std(double(cellFL(:)));
            cTimelapse.extractedData(channel).radius(j,timepoint)=trapInfo(currTrap).cell(temp_loc).cellRadius;
            
        end
    end
end