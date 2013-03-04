function loadSavedExperiment(cExpGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously created cExperiment variable') ;
load(fullfile(PathName,FileName),'cExperiment');
cExpGUI.cExperiment=cExperiment;

set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
