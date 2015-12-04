function autoSelect(cExpGUI)

if isempty(cExpGUI.cExperiment.saveFolder)
    cExpGUI.cExperiment.saveFolder=cExpGUI.cExperiment.rootFolder;
end

posVals=get(cExpGUI.posList,'Value');


cExpGUI.cExperiment.selectCellsToPlotAutomatic(posVals);
