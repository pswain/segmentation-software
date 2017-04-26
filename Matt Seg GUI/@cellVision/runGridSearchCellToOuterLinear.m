function runGridSearchCellToOuterLinear(cCellSVM,ss,cmd)
% grid search for best parameters in the edge | centre to outer
% classification.

bestcv = 0;
if nargin<2
    ss=15;
end

if nargin<3
    cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
end

% pick out centres edges against outer pixels
class_labels = cCellSVM.trainingData.class;
class_labels = 1*ismember(class_labels,[1,2]);


for log2c = -2:2,
    cmd1 = [cmd, num2str(2^log2c)];
    cv = train(class_labels(1,1:ss:end)', sparse(cCellSVM.trainingData.features(1:ss:end,:)), cmd1);
    if (cv >= bestcv),
        bestcv = cv; bestc = 2^log2c;
    end
    fprintf('%g %g (best c=%g)\n', log2c, cv, bestc, bestcv);
end

cCellSVM.trainingParams.cost=bestc;
cCellSVM.trainingParams.gamma=1;