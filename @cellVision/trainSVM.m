function trainSVM(cCellSVM,ss,cmd)

if nargin<3
    cmd = ['-t 2 -w0 1 -w1 1 -c ', num2str(cCellSVM.trainingParams.cost),' -g ',num2str(cCellSVM.trainingParams.gamma)];
end

if nargin<2
    ss=15;
end
% cCellSVM.SVMModel = svmtrain(cCellSVM.trainingData.class(1,1:ss:end)', cCellSVM.trainingData.features(1:ss:end,:),cmd)



cCellSVM.SVMModel = svmtrain2(cCellSVM.trainingData.kernel_class(1,1:ss:end)', cCellSVM.trainingData.kernel_features(1:ss:end,:),cmd)

