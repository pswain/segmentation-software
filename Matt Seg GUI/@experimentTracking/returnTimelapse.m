function cTimelapse=returnTimelapse(cExperiment,timelapseNum)

if isempty(cExperiment.saveFolder)
    cExperiment.saveFolder=cExperiment.rootFolder;
end
load([cExperiment.saveFolder '/' cExperiment.dirs{timelapseNum},'cTimelapse']);

