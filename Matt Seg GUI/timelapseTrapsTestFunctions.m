%load a cTimelapse

%% returnSegmentationTrapStack

tp = 50
traps = 1:length(cTimelapse.cTimepoint(tp).trapInfo);
tic;B = returnSegmenationTrapsStack(cTimelapse,1:24,50);toc
for i=traps
    for ci = 1:length(cTimelapse.channelsForSegment)
if any((B{i}(:,:,ci) ~= cTimelapse.returnTrapsTimepoint(i,tp,cTimelapse.channelsForSegment(ci))) )
    fprintf('error')
end
    end
end