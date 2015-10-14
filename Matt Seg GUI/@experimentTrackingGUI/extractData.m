function extractData(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
[choice ok]=listdlg('ListString',cExpGUI.cExperiment.OmeroDatabase.Channels);
cExpGUI.cExperiment.extractCellInformation(posVals,'not determined',choice);
