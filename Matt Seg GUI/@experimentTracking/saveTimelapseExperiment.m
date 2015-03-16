function saveTimelapseExperiment(cExperiment,currentPos)
    cTimelapse=cExperiment.cTimelapse;

    save([cExperiment.saveFolder filesep,cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');
%     save([cExperiment.rootFolder '/',cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');

 cExperiment.cTimelapse=[];   
     cCellVision=cExperiment.cCellVision;
    cExperiment.cCellVision=[];
save([cExperiment.saveFolder '/cExperiment'],'cExperiment','cCellVision');
    cExperiment.cCellVision=cCellVision;
