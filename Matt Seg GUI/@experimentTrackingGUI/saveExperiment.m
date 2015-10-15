function saveExperiment(cExpGUI)

cExperiment = cExpGUI.cExperiment;
cCellVision = cExpGUI.cCellVision;

oldFolder=cd(cExperiment.rootFolder);
[FileName,PathName,FilterIndex] = uiputfile('cExperiment','Name of current experiment') ;

save(fullfile(PathName,FileName),'cExperiment','cCellVision');

cd(oldFolder);