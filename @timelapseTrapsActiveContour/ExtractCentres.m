function [Centres,ColumnNames] = ExtractCentres(ttacObject,FirstTimepoint,LastTimepoint)
%small method to extract centres and labels and store them in a data
%as an array which it passes back

figToPlot = figure;

Timepoints = FirstTimepoint:LastTimepoint;

Centres = zeros(length(Timepoints)*100,5); %[TimePoint TrapNumber CellLabel xLabel yLabel]

ColumnNames = {'TimePoint' 'TrapNumber' 'CellLabel' 'XCoord' 'Ycoord'};

CellsToPlotGiven = false;
if ~isempty(ttacObject.TimelapseTraps.cellsToPlot)
    CellsToSegment = full(ttacObject.TimelapseTraps.cellsToPlot);
else
    CellsToPlotGiven = false;
end

if ~any(ismember(Timepoints,1:length(ttacObject.TimelapseTraps.cTimepoint)))
    error('timpoints passed to SegmentConsecutiveTimePoints are not valid timepoints\n')
end

CellsRecorded = 1;

for TP = Timepoints;
            
for TI = 1:size(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo,2)
    
    if ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellsPresent
        for CI = 1:size(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell,2)
            
            if (CellsToPlotGiven && CellsToSegment(TI,ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI))) || ~CellsToPlotGiven
                
                Centres(CellsRecorded,1) = TP;
                Centres(CellsRecorded,2) = TI;
                Centres(CellsRecorded,3) = ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cellLabel(CI);
                CellCentres =double(ttacObject.TimelapseTraps.cTimepoint(TP).trapInfo(TI).cell(CI).cellCenter);
                TrapCentres = [ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(TI).xcenter ttacObject.TimelapseTraps.cTimepoint(TP).trapLocations(TI).ycenter];
                Centres(CellsRecorded,4:5) = CellCentres + TrapCentres - [ttacObject.TimelapseTraps.cTrapSize.bb_width ttacObject.TimelapseTraps.cTrapSize.bb_height];
                
                CellsRecorded = CellsRecorded+1;
                
            end   
        end
    end
    
end

if false
    toplot = Centres(:,1) == TP;
    figure(figToPlot);imshow(ttacObject.TimelapseTraps.returnSingleTimepoint(TP),[])
    hold on
    plot(Centres(toplot,4),Centres(toplot,5),'or')
    hold off
    pause
end

end

end


