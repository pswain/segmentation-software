function changeRootDirAllTimelapses(cExperiment,dirsToSearch)

if nargin<2
    dirsToSearch=1:length(cExperiment.dirs);
end

fprintf(['Select the correct folder for: \n',cExperiment.rootFolder '\n']);
helpdlg('This is the new root folder containing all images of the timelapse objects');

newRootFolder=uigetdir(pwd,['Select the correct folder for: ',cExperiment.rootFolder]);
oldRootFolder=cExperiment.rootFolder;

for i=1:length(dirsToSearch)
    posIndex=dirsToSearch(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{posIndex},'cTimelapse']);

    newDir=strrep(cTimelapse.timelapseDir,oldRootFolder,newRootFolder);
    cTimelapse.timelapseDir=newDir;
    
        cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(posIndex);
end
cExperiment.rootFolder=newRootFolder;
cExperiment.saveExperiment;

