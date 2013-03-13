function trainSVMLinear(cCellSVM,ss,cmd)

if nargin<3
    cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellSVM.trainingParams.cost)];
end

if nargin<2
    ss=1;
end
% cCellSVM.SVMModel = train(cCellSVM.trainingData.class(1,1:ss:end)', sparse(cCellSVM.trainingData.features(1:ss:end,:)),cmd)
cCellSVM.SVMModelLinear = train(cCellSVM.trainingData.class(1,1:ss:end)', sparse(cCellSVM.trainingData.features(1:ss:end,:)),cmd)

