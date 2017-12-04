function autoSelect(cExpGUI)

if isempty(cExpGUI.cExperiment.saveFolder)
    cExpGUI.cExperiment.saveFolder=cExpGUI.cExperiment.rootFolder;
end

posVals=get(cExpGUI.posList,'Value');

% reset parameters so user again selects.
cExpGUI.cExperiment.cellAutoSelectParams = [];

cExpGUI.cExperiment.selectCellsToPlotAutomatic(posVals);
