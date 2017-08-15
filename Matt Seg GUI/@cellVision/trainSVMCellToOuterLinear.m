function trainSVMCellToOuterLinear(cCellVision,step_size,training_command)
%trainSVMCellToOuterLinear(cCellSVM,ss,cmd)
% train the cellVision model for distinguinshing centre|edge from outer
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
class_labels = cCellVision.trainingData.class;
class_labels = 1*ismember(class_labels,[1,2]);

cCellVision.SVMModelCellToOuterLinear = train(class_labels(1,1:step_size:end)', sparse(cCellVision.trainingData.features(1:step_size:end,:)),training_command);
cCellVision.TrainData = date;

