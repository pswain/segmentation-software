function loadSavedExperiment(cExpGUI)

[FileName,PathName] = uigetfile('*.mat','Name of previously created cExperiment variable') ;

if isequal(FileName,0) || isequal(PathName,0)
    return
end

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
    cExpGUI.cExperiment.cCellVision=l1.cCellVision;
end

switch answer
    case 'Yes'
        cExpGUI.cExperiment.saveExperiment;
end

set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);
cExpGUI.channel = 1;

% select traps not necessary for non-trap timelapses
if ~cExpGUI.cExperiment.trapsPresent && any(cExpGUI.cExperiment.posTracked)
    set(cExpGUI.selectTrapsToProcessButton,'Enable','off');
else
    set(cExpGUI.selectTrapsToProcessButton,'Enable','on');
end

set(cExpGUI.posList,'Value',1);
set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);
set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
set(cExpGUI.figure,'Name',cExpGUI.cExperiment.saveFolder);
