function cellID=getNearestPlotLine( src,cData )
%GETNEARESTPLOTLINE Return the ID of the plot line closest to point clicked
if ~any(cData.cellsToPlot)
    disp('No lines to plot')
    return
end

pos=get(src,'currentpoint');
timepoint=round(pos(1,1)); yValue=pos(1,2);
data=cData.cTimelapse.extractedData(2);
intensity=data.max5./data.median;

timepointValues=abs(intensity(:,timepoint)-yValue);
sortTV=sort(timepointValues);
[position, ~]=find(timepointValues==sortTV(1));
disp(position);
cData.highlightedCell=position;
end

