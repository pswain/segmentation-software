function saveTimelapseExperiment(cExperiment,currentPos)
    cTimelapse=cExperiment.cTimelapse;

    save([cExperiment.rootFolder '/',cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');
%     save([cExperiment.rootFolder '/',cExperiment.dirs{currentPos},'cTimelapse'],'cTimelapse');

 cExperiment.cTimelapse=[];   
     cCellVision=cExperiment.cCellVision;
    cExperiment.cCellVision=[];
save([cExperiment.rootFolder '/cExperiment'],'cExperiment','cCellVision');
    cExperiment.cCellVision=cCellVision;
