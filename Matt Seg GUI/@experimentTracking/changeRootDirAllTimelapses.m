function changeRootDirAllTimelapses(cExperiment,dirsToSearch)

if nargin<2
    dirsToSearch=1:length(cExperiment.dirs);
end

fprintf(['Select the correct folder for: \n',cExperiment.rootFolder '\n']);
helpdlg('This is the new root folder containing all images of the timelapse objects');

newRootFolder=uigetdir(pwd,['Select the correct folder for: ',cExperiment.rootFolder]);
oldRootFolder=cExperiment.rootFolder;

cExperiment.saveFolder=uigetdir(pwd,['Select the folder where you want to save the timelapses: ',cExperiment.rootFolder]);

cExperiment.rootFolder=newRootFolder;
for i=1:length(dirsToSearch)
    posIndex=dirsToSearch(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{posIndex},'cTimelapse']);
    if i==1
        oldRootFolder=cTimelapse.timelapseDir;
    end
    newDir=strrep(cTimelapse.timelapseDir,oldRootFolder,newRootFolder);
    newDir=[newRootFolder '/' cExperiment.dirs{posIndex}];
    cTimelapse.timelapseDir=newDir;
    
        cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(posIndex);
end
cExperiment.rootFolder=newRootFolder;
cExperiment.saveExperiment;

