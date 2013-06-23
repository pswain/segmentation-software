function saveClassificationOnly(cCellSVM)
cCellVision=cCellSVM;
[FileName,PathName,FilterIndex] = uiputfile('cCellVision.mat') ;

cCellVision.trainingData=[];

save(fullfile(PathName,FileName),'cCellVision');