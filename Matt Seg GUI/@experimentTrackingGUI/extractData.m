function extractData(cExpGUI)

posVals=get(cExpGUI.posList,'Value');

options.Default='No';
options.Interpreter = 'tex';
choice = questdlg('Change offsets before extracting the data? - 0 & 2 for Batgirl?','Offset Change',...
    'Yes','No',options);

if strcmp(choice,'Yes')
    cExpGUI.cExperiment.setChannelOffset;
end

cExpGUI.cExperiment.extractCellInformation(posVals);
