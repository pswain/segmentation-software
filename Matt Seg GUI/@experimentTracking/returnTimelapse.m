function cTimelapse=returnTimelapse(cExperiment,timelapseNum)

load([cExperiment.saveFolder '/' cExperiment.dirs{timelapseNum},'cTimelapse']);

