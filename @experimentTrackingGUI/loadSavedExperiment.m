function loadSavedExperiment(cExpGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously created cExperiment variable') ;
load(fullfile(PathName,FileName),'cExperiment');
cExpGUI.cExperiment=cExperiment;



%This section was added by Elco. Put in a try catch because experiment
%files saved before the saveTimelapse file was written wouldn't have
%cCellvision models. 
%Also check with Matt if it's really necessary.
try
    load(fullfile(PathName,FileName),'cCellVision');
    cExpGUI.cCellVision= cCellVision;
catch

    fprintf('no cell vision model found. Please load one. \n \n')
    
end


set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
