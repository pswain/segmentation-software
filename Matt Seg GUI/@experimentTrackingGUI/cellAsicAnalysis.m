function cellAsicAnalysis( cExpGUI )

pos=get(cExpGUI.posList,'Value');
pos=pos(1);
cellsToPlot=sparse(100,100);
cTimelapse=cExpGUI.cExperiment.returnTimelapse(pos);
cExpGUI.currentGUI=displayCellAsicData(cTimelapse,cellsToPlot);

end

