function saveExperiment(cExperiment)
%     save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
    
    cCellVision=cExperiment.cCellVision;
    cExperiment.cCellVision=[];
    save([cExperiment.saveFolder '/cExperiment'],'cExperiment','cCellVision');
    cExperiment.cCellVision=cCellVision;

