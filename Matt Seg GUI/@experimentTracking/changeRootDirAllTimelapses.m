function changeRootDirAllTimelapses(cExperiment,dirsToSearch,newRootFolder)

if nargin<2 || isempty(dirsToSearch)
    dirsToSearch=1:length(cExperiment.dirs);
end

if nargin<3 || isempty(newRootFolder)

fprintf(['Select the correct folder for: \n',cExperiment.rootFolder '\n']);
h = helpdlg('This is the new root folder containing all images of the timelapse objects');
waitfor(h);

newRootFolder=uigetdir(pwd,['Select the correct folder for: ',cExperiment.rootFolder]);
end
% cExperiment.saveFolder=uigetdir(pwd,['Select the folder where you want to save the timelapses: ',cExperiment.rootFolder]);

cExperiment.rootFolder=newRootFolder;
for i=1:length(dirsToSearch)
    posIndex=dirsToSearch(i);
    load([fullfile(cExperiment.saveFolder , cExperiment.dirs{posIndex}) 'cTimelapse']);
    newDir=fullfile(newRootFolder , cExperiment.dirs{posIndex});
    cTimelapse.timelapseDir=newDir;
    
    cExperiment.cTimelapse=cTimelapse;
    if i==length(dirsToSearch)
        cExperiment.saveTimelapseExperiment(posIndex);
    else
        cExperiment.saveTimelapse(posIndex);
    end
end
cExperiment.rootFolder=newRootFolder;
cExperiment.saveExperiment;

