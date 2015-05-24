function group_posNums = extractProperPosNums(cExperiment,groupings)
% function to pick out which posNum's correspond to which positions
% final useful output is group_posNums - a cell array where each entry is
% an array of the posNums corresponding to the equivalent group specified
% in groupings
% expects a cExperiment to be in the workspace
%
%  INPUTS
%
% cExperiment - standard
%
% groupings   - (position numbers corresponding to group 1 and 2 as written in the directory names)
%               example: groupings = {1:20 21:40}


grouping_names = {};
for groupi = 1:length(groupings)
    
    group_names{groupi} = arrayfun(@(x) sprintf('pos%d',x),groupings{groupi},'UniformOutput',false);
    
end

group_posNums = {};

for groupi = 1:length(groupings)
    
    group_posNums{groupi} = cellfun(@(x) any(strcmp(group_names{groupi},x)),cExperiment.dirs,'UniformOutput',true);
    group_posNums{groupi} = find(group_posNums{groupi});
end

end

