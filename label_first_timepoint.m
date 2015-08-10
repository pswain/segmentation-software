for i=1:length(cTimelapse.cTimepoint(1).trapInfo)
cTimelapse.cTimepoint(1).trapInfo(i).cellLabel = 1:length(cTimelapse.cTimepoint(1).trapInfo(i).cell);
end


for i= 1:length(cTimelapse.cTimepoint(1).trapInfo)
cTimelapse.cTimepoint(1).trapMaxCell(i) = cTimelapse.cTimepoint(1).trapInfo(i).cellLabel(end);
end


%% ckear out cell info
for i= 2:length(cTimelapse.cTimepoint)
cTimelapse.cTimepoint(i).trapInfo = cTimelapse.cTimepoint(end).trapInfo;
end
