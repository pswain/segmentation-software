function loadSavedExperiment(cExpGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously created cExperiment variable') ;
l1 = load(fullfile(PathName,FileName));
cExpGUI.cExperiment=l1.cExperiment;

if isfield(l1,'cCellVision')
    cExpGUI.cCellVision= l1.cCellVision;
    cExpGUI.cExperiment.cCellVision=l1.cCellVision;
end


set(cExpGUI.posList,'Value',1);
set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
set(cExpGUI.figure,'Name',cExpGUI.cExperiment.saveFolder);
