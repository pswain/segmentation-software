function selectCellsToPlot(cExperiment,cCellVision,position)

if nargin<3
    position=1;
end
cTimelapse=cExperiment.returnTimelapse(position);

cTrapDisplayPlot(cExperiment,cTimelapse,cCellVision)
