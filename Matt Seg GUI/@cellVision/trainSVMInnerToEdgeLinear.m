function trainSVMInnerToEdgeLinear(cCellVision,step_size,training_command)
% trainSVMCellToOuterLinear(cCellSVM,ss,cmd)
% train the cellVision model for distinguinshing centre from edge
% based on the cCellVision.trainingData. Expects interiors to have class 1,
% edges to have class 2 and background to have class 0.
%
% cCellVision       -   cellVision model to train.
% step_size         -   will use only every 'step_size'th pixel. Set to
%                       1 (default)to use all.
% training_command  -   command passed to libsvm training library.
% 
% uses the libsvm library.
if nargin<3
    training_command = ['-s 1 -w0 1 -w1 1 -c ', num2str(cCellVision.trainingParams.cost)];
end

if nargin<2
    step_size=1;
end

% pick out centres edges against outer pixels
class_labels = cCellVision.trainingData.class(1,1:step_size:end);
features = cCellVision.trainingData.features(1:step_size:end,:);

% knock out any zeros (outer pixels);
features(class_labels==0,:) = [];
class_labels(class_labels==0) = [];

% set edges to true
class_labels= 1*(class_labels==1);

cCellVision.SVMModelInnerToEdgeLinear = train(class_labels', sparse(features),training_command);
cCellVision.TrainData = date;

