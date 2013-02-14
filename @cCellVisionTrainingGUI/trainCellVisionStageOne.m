function trainCellVisionStageOne(cCellVisionGUI)



step_size=1;
cCellVisionGUI.cCellVision.generateTrainingSetTimelapse(cCellVisionGUI.cTimelapse,step_size);
cCellVisionGUI.cCellVision.trainingParams.cost=4;
cCellVisionGUI.cCellVision.trainingParams.gamma=1;
cCellVisionGUI.cCellVision.negativeSamplesPerImage=7e3;

step_size=1;
cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellVisionGUI.cCellVision.trainingParams.cost)];
answer = inputdlg('Enter the libLinear commands you would like to run','BoundingBox',1,{cmd})

% cCellVision.runGridSearchLinear(step_size)
cmd=answer{1};
tic;cCellVisionGUI.cCellVision.trainSVMLinear(step_size,cmd);toc