function addSecondaryChannel(cExpGUI)

searchString = inputdlg('Enter the string to search for the secondary (fluorescent) channel images','SearchString',1,{'GFP'});

for i=1:length(cExpGUI.cExperiment.dirs)
    cExpGUI.cExperiment.cTimelapse=cExpGUI.cExperiment.returnTimelapse(i);
    cExpGUI.cExperiment.cTimelapse.addSecondaryTimelapseChannel(searchString);
    cExpGUI.cExperiment.saveTimelapseExperiment(i);
end