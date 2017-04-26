function trainSVMCellToOuterLinear(cCellSVM,ss,cmd)
% train the cellVision model for distinguinshing centre|edge from outer
if nargin<3
    cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellSVM.trainingParams.cost)];
end

if nargin<2
    ss=1;
end

% pick out centres edges against outer pixels
class_labels = cCellSVM.trainingData.class;
class_labels = 1*ismember(class_labels,[1,2]);

cCellSVM.SVMModelCellToOuterLinear = train(class_labels(1,1:ss:end)', sparse(cCellSVM.trainingData.features(1:ss:end,:)),cmd);
cCellSVM.TrainData = date;

