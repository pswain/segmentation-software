function trainSVMInnerToEdgeLinear(cCellSVM,ss,cmd)
% train the cellVision model for distinguinshing Inner pixels from edge
if nargin<3
    cmd = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellSVM.trainingParams.cost)];
end

if nargin<2
    ss=1;
end

% pick out centres edges against outer pixels
class_labels = cCellSVM.trainingData.class(1,1:ss:end);
features = cCellSVM.trainingData.features(1:ss:end,:);

% knock out any zeros (outer pixels);
features(class_labels==0,:) = [];
class_labels(class_labels==0) = [];

% set edges to true
class_labels= 1*(class_labels==1);


cCellSVM.SVMModelInnerToEdgeLinear = train(class_labels', sparse(features),cmd);
cCellSVM.TrainData = date;

