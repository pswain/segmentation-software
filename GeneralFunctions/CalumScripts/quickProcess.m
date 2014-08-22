
exp=experimentTrackingGUI;
posVals=1:4;
%04-06-13
exp.loadCellVision('cCellVision_linear_10000neg_betterSegAreas.mat','C:\shared\Cellasic data (Hille) for training\Training');
exp.loadSavedExperiment('C:\shared\Cellasic data (Hille) for training\04-06-13\Output','cExperiment.mat');
exp.automaticProcessing(1,posVals);

%09-05-13
exp.loadCellVision('cCellVision_linear_10000neg_betterSegAreas.mat','C:\shared\Cellasic data (Hille) for training\Training');
exp.loadSavedExperiment('C:\shared\Cellasic data (Hille) for training\09-05-13\Output','cExperiment.mat');
exp.automaticProcessing(1,posVals);

%30-04-13
exp.loadCellVision('cCellVision_linear_10000neg_betterSegAreas.mat','C:\shared\Cellasic data (Hille) for training\Training');
exp.loadSavedExperiment('C:\shared\Cellasic data (Hille) for training\30-04-13\Output','cExperiment.mat');
exp.automaticProcessing(1,posVals);

compareTimelapses;