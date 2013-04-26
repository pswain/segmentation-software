function saveTimelapseExperiment(cExperiment,currentPos)
    cTimelapse=cExperiment.cTimelapse;

    save([cExperiment.rootFolder '/',cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');
 cExperiment.cTimelapse=[];   
save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
