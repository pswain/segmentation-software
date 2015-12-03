function autoSelect(cExpGUI)

if isempty(cExpGUI.cExperiment.saveFolder)
    cExpGUI.cExperiment.saveFolder=cExpGUI.cExperiment.rootFolder;
end

posVals=get(cExpGUI.posList,'Value');
    load([cExpGUI.cExperiment.saveFolder '/' cExpGUI.cExperiment.dirs{1},'cTimelapse']);


cExpGUI.cExperiment.selectCellsToPlotAutomatic(posVals);
