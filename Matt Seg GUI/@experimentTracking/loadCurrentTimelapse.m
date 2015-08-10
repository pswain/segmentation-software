function cTimelapse=loadCurrentTimelapse(cExperiment,positionsToLoad)

    
    load([cExperiment.saveFolder '/' cExperiment.dirs{positionsToLoad},'cTimelapse']);
    cExperiment.cTimelapse=cTimelapse;
    