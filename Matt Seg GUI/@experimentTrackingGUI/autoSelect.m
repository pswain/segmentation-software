function autoSelect(cExpGUI)

if isempty(cExpGUI.cExperiment.saveFolder)
    cExpGUI.cExperiment.saveFolder=cExpGUI.cExperiment.rootFolder;
end

posVals=get(cExpGUI.posList,'Value');
cTimelapse=cExpGUI.cExperiment.loadCurrentTimelapse(1);%Why is this loadCurrentTimelapse, not returnTimelapse?

cExpGUI.cExperiment.selectCellsToPlotAutomatic(posVals);
