function runGridSearchCellToOuterLinear(cCellSVM,step_size,training_command)
% grid search for best hyper parameters in the edge | centre to outer
% classifier training. Uses the cCellVision.trainingData: expects interiors
% to have class 1, edges to have class 2 and background to have class 0.
%
% cCellVision       -   cellVision model to train.
% step_size         -   will use only every 'step_size'th pixel. Set to
%                       1 (default)to use all.
% training_command  -   command passed to libsvm training library.
% 
% uses the libsvm library.
bestcv = 0;
if nargin<2
    step_size=15;
end

if nargin<3
    training_command='-s 1 -w0 1 -w1 1 -v 5 -c ';
end

% pick out centres edges against outer pixels
class_labels = cCellSVM.trainingData.class;
class_labels = 1*ismember(class_labels,[1,2]);


for log2c = -2:2
    cmd1 = [training_command, num2str(2^log2c)];
    cv = train(class_labels(1,1:step_size:end)', sparse(cCellSVM.trainingData.features(1:step_size:end,:)), cmd1);
    if (cv >= bestcv)
        bestcv = cv; bestc = 2^log2c;
    end
    fprintf('%g %g (best c=%g)\n', log2c, cv, bestc, bestcv);
end

cCellSVM.trainingParams.cost=bestc;
cCellSVM.trainingParams.gamma=1;