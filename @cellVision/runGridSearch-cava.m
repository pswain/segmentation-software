function runGridSearch(cCellSVM,ss,cmd)

if nargin<2
    ss=15;
end


bestcv = 0;
for log2c = -1:3,
  for log2g = -4:2,
    cmd = ['-t 2 -w0 1 -w1 1 -v 5 -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
%     cv = svmtrain(cCellSVM.trainingData.kernel_class(1,1:ss:end)', (cCellSVM.trainingData.kernel_features(1:ss:end,:)), cmd);
    cv = svmtrain(cCellSVM.trainingData.class(1,1:ss:end)', (cCellSVM.trainingData.features(1:ss:end,:)), cmd);

    if (cv >= bestcv),
      bestcv = cv; bestc = 2^log2c; bestg = 2^log2g;
    end
    fprintf('%g %g %g (best c=%g, g=%g, rate=%g)\n', log2c, log2g, cv, bestc, bestg, bestcv);
  end
end

cCellSVM.trainingParams.cost=bestc;
cCellSVM.trainingParams.gamma=bestg;