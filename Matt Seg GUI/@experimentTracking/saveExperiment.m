function saveExperiment(cExperiment,fileName)
%     save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
    
if nargin<2
    cCellVision=cExperiment.cCellVision;
    cExperiment.cCellVision=[];
    save([cExperiment.saveFolder '/cExperiment'],'cExperiment','cCellVision');
    cExperiment.cCellVision=cCellVision;
    
else
        cCellVision=cExperiment.cCellVision;
    cExperiment.cCellVision=[];
    save([cExperiment.saveFolder '/' fileName],'cExperiment','cCellVision');
    cExperiment.cCellVision=cCellVision;
end

