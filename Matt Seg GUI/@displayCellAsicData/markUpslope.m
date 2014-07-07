function markUpslope( cData )
%Mark on the plot a position where the upslope begins
%Modify cData.upslopes(cellNum, timepoint) to show the upslope on the
%intensity (max5/median) plot.
%   Invoked via button. Press button on an already existing marker to
%   remove it
%Reccomend using the first frame with intensity significantly above
%background level
timepoint=get(cData.timepointSlider,'value');
if isempty(cData.highlightedCell)
    return
end

if cData.upslopes(cData.highlightedCell,timepoint)==0
    cData.upslopes(cData.highlightedCell,timepoint)=1;
elseif cData.upslopes(cData.highlightedCell,timepoint)==1
    cData.upslopes(cData.highlightedCell,timepoint)=0;    
end
updatePlot(cData);
saveData(cData, cData.filepath)

end

