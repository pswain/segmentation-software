function RunActiveContourExperimentTracking(cExperiment,positionsToIdentify,FirstTimepoint,LastTimepoint,OverwriteTimelapseParameters)

if nargin<2 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end

LowestAllowedTimepoint = min(cExperiment.timepointsToProcess(:));
HighestAllowedTimepoint = max(cExperiment.timepointsToProcess(:));

if nargin <4 || (isempty(FirstTimepoint) || isempty(LastTimepoint))
    answer = inputdlg(...
        {'Enter the timepoint at which to begin the active contour method' ;'Enter the timepoint at which to stop'},...
        'start and end times of active contour method',...
        1,...
        {int2str(LowestAllowedTimepoint); int2str(HighestAllowedTimepoint)});
    
    FirstTimepoint = str2num(answer{1});
    LastTimepoint = str2num(answer{2});
  
end

if FirstTimepoint<LowestAllowedTimepoint
    FirstTimepoint = LowestAllowedTimepoint;
end

if LastTimepoint>HighestAllowedTimepoint
    LastTimepoint = HighestAllowedTimepoint;
end


if nargin<5 || ~isempty(OverwriteTimelapseParameters)
    OverwriteTimelapseParameters = false;
end

if isempty(cExperiment.ActiveContourParameters)
    cExperiment.ActiveContourParameters = timelapseTrapsActiveContour.LoadDefaultParameters;
end

    
%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load(fullfile(cExperiment.saveFolder,[ cExperiment.dirs{currentPos} 'cTimelapse']),'cTimelapse');
    
    if isempty(cTimelapse.ActiveContourObject)
        cTimelapse.InstantiateActiveContourTimelapseTraps(cExperiment.ActiveContourParameters);
    end
    
    if OverwriteTimelapseParameters
        cTimelapse.ActiveContourObject.Parameters = cExperiment.ActiveContourParameters;
    end
    
    if cTimelapse.ActiveContourObject.TrapPresentBoolean &&( isempty(cTimelapse.ActiveContourObject.TrapLocation{FirstTimepoint}) || isempty(cTimelapse.ActiveContourObject.TrapPixelImage))
        fprintf('getting trap information from cCellVision of cExperiment object \n')
        cTimelapse.ActiveContourObject.getTrapInfoFromCellVision(cExperiment.cCellVision);
    end
    
    cTimelapse.RunActiveContourTimelapseTraps(FirstTimepoint,LastTimepoint);
    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
    
    fprintf('finished position %d of %d \n \n',i,length(positionsToIdentify))
end

fprintf('finished running active contour method on experiment\n \n')

end

