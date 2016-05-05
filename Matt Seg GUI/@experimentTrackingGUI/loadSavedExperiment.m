function loadSavedExperiment(cExpGUI)

[FileName,PathName,FilterIndex] = uigetfile('*.mat','Name of previously created cExperiment variable') ;
l1 = load(fullfile(PathName,FileName));
cExpGUI.cExperiment=l1.cExperiment;

answer = 'No';
if ~strcmp(cExpGUI.cExperiment.saveFolder,PathName(1:(end-1)))
    answer = questdlg('The save folder from which this file was loaded does not match the save location of the cExperiment. Would you like to make them match? (If you have no idea what this means, press ''yes'')','change saveFolder');
    switch answer
        case 'Yes'
            cExpGUI.cExperiment.saveFolder = PathName(1:(end-1));
        case 'Cancel'
            fprintf('\n\n    Experiment loading cancelled')
            cExpGUI.cExperiment = [];
        return
end

end


if isfield(l1,'cCellVision')
    cExpGUI.cCellVision= l1.cCellVision;
    cExpGUI.cExperiment.cCellVision=l1.cCellVision;
end

switch answer
    case 'Yes'
        cExpGUI.cExperiment.saveExperiment;
end


set(cExpGUI.posList,'Value',1);
set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
set(cExpGUI.figure,'Name',cExpGUI.cExperiment.saveFolder);
