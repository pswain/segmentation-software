function selectCellsToPlotAutomatic(cExperiment,params)

if nargin<2
    params.fraction=.8; %fraction of timelapse length that cells must be present or
    params.duration=3e3; %number of frames cells must be present
%     params.cellsToCheck=4;
    params.framesToCheck=100;
end

cExperiment.cellsToPlot=zeros(size(cExperiment.cellsToPlot))>0;
positionsToCheck=find(cExperiment.posTracked);
for i=1:length(positionsToCheck)
    expPos=positionsToCheck(i);
    disp(['Experimental Position Number ' int2str(expPos)]);
    cTimelapse=cExperiment.returnTimelapse(expPos);
    cTimepoint=cTimelapse.cTimepoint;

    
    for trap=1:length(cTimelapse.cTimepoint(1).trapInfo)
        disp(['Trap Number ' int2str(trap)]);
        cellLabels=zeros(1,100*length(cTimelapse.cTimepoint));
        cellsSeen=[];
        index=0;
        for timepoint=1:length(cTimelapse.cTimepoint)
            tempLabels=cTimepoint(timepoint).trapInfo(trap).cellLabel;
            cellLabels(1,index+1:index+length(tempLabels))=tempLabels;
            if timepoint==params.framesToCheck
                cellsSeen=max(cellLabels);
            end
            index=index+length(tempLabels);
        end
        tempLabels=cellLabels(1:index);
        cellLabels=tempLabels;
        n=hist(cellLabels,max(cellLabels));
        
        locs=find(n>=length(cTimelapse.cTimepoint)*params.fraction | n>=params.duration);
        
        if ~isempty(cellsSeen) && ~isempty(locs)
            locs=locs(locs<=cellsSeen);
            if ~isempty(locs)
                for cellsForPlot=1:length(locs)
                    cTimelapse.cellsToPlot(trap,locs(cellsForPlot))=1;
                end
            end
        end
    end
    save([cExperiment.rootFolder '/'],[cExperiment.dirs{currentPos}, 'cTimelapse']);

end