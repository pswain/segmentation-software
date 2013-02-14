function trainCellVisionStageTwo(cCellVisionGUI)


cCellVisionGUI.cCellVision.twoStageThresh=1;
step_size=1;
cCellVisionGUI.cCellVision.generateTrainingSet2Stage(cCellVisionGUI.cTimelapse,step_size);

cCellVisionGUI.cCellVision.trainingParams.cost=4
cCellVisionGUI.cCellVision.trainingParams.gamma=.25 %or 2 and .25 or 2 and 1 or 1 and 2

%
step_size=1;
cmd = ['-t 2 -w0 1 -w1 1 -c ', num2str(cCellVisionGUI.cCellVision.trainingParams.cost),' -g ',num2str(cCellVisionGUI.cCellVision.trainingParams.gamma)];
answer = inputdlg('Enter the libSVM commands you would like to run','BoundingBox',1,{cmd})
cmd=answer{1};
tic;cCellVisionGUI.cCellVision.trainSVM(step_size,cmd);toc