function changeRootDirAllTimelapses(cExperiment,dirsToSearch,newRootFolder)
% changeRootDirAllTimelapses(cExperiment,dirsToSearch,newRootFolder)
%
% changes the timelapseDir property of every cTimelapse covered by the
% cExperiment.

if nargin<2 || isempty(dirsToSearch)
    dirsToSearch=1:length(cExperiment.dirs);
end

if nargin<3 || isempty(newRootFolder)

%fix for windows file systems:
oldRootFolder = cExperiment.rootFolder;

if ischar(oldRootFolder)
    oldRootFolder = regexprep(oldRootFolder,'\\','/');
end

fprintf('Select the correct folder for: \n %s \n',oldRootFolder);
h = helpdlg('This is the new root folder containing all images of the timelapse objects');
waitfor(h);

newRootFolder=uigetdir(pwd,sprintf('Select the correct folder for: %s',oldRootFolder));
if newRootFolder==0
    
    fprintf('\n\nchangeRootDirAll cancelled\n\n')
    return
    
end
end
% cExperiment.saveFolder=uigetdir(pwd,['Select the folder where you want to save the timelapses: ',cExperiment.rootFolder]);

cExperiment.rootFolder=newRootFolder;
for i=1:length(dirsToSearch)
    posIndex=dirsToSearch(i);
    load([fullfile(cExperiment.saveFolder , cExperiment.dirs{posIndex}) 'cTimelapse']);
    newDir=fullfile(newRootFolder , cExperiment.dirs{posIndex});
    cTimelapse.timelapseDir=newDir;
    
        cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(posIndex);
    fprintf('%d ',i);
end
cExperiment.rootFolder=newRootFolder;
cExperiment.saveExperiment;
fprintf('\n\n')

