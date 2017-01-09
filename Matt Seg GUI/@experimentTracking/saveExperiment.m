function saveExperiment(cExperiment)
% SAVEEXPERIMENT(cExperiment)
% save the experiment in the saveFolder.

cCellVision=cExperiment.cCellVision;
cExperiment.cCellVision=[];
save([cExperiment.saveFolder filesep 'cExperiment.mat'],'cExperiment','cCellVision');
cExperiment.cCellVision=cCellVision;

end


