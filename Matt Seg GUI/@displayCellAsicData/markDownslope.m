function markDownslope( cData )
%Mark on the plot a position where the upslope begins
%Modify cData.downslopes(cellNum, timepoint) to show the downslope on the
%intensity (max5/median pixel  brightness) plt
%   Invoked via button. Press button on an already existing marker to
%   remove it
%Reccomend using the first frame with an intensity at average level

timepoint=get(cData.timepointSlider,'value');
if isempty(cData.highlightedCell)
    return
end

if cData.downslopes(cData.highlightedCell,timepoint)==0
    cData.downslopes(cData.highlightedCell,timepoint)=1;
elseif cData.downslopes(cData.highlightedCell,timepoint)==1
    cData.downslopes(cData.highlightedCell,timepoint)=0;    
end
updatePlot(cData);
saveData(cData, cData.filepath)
end