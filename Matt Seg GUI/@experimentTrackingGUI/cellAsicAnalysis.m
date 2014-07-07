function cellAsicAnalysis( cExpGUI )

pos=get(cExpGUI.posList,'Value');
pos=pos(1);
cellsToPlot=sparse(100,100);
filepath=[cExpGUI.cExperiment.saveFolder filesep 'CellAsicData_' int2str(pos)];
cTimelapse=cExpGUI.cExperiment.returnTimelapse(pos);
cExpGUI.currentGUI=displayCellAsicData(cTimelapse,cellsToPlot,filepath);

end

