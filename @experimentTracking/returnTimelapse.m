function cTimelapse=returnTimelapse(cExperiment,timelapseNum)

load([cExperiment.rootFolder '/' cExperiment.dirs{timelapseNum},'cTimelapse']);

