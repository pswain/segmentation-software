function updatePlot( cData )
%UPDATEPLOT Update the plotted data
%   Only call this function when a change is made to either the data or the
%   list of cells to be plotted
%
%   Extracted data is stored seperately from cell data, in order of
%   original arrangement. Need to find index of current cell in original
%   plot
[~,originalCells]=find(cData.cTimelapse.cellsToPlot);
[~, labels]=find(cData.cellsToPlot);
timepoint=get(cData.timepointSlider,'value');
data = cData.cTimelapse.extractedData;
cla(cData.plotAxes);
hold(cData.plotAxes,'on');
for i=1:length(labels)
    [position,~]=find(originalCells==labels(i));
    numTimepoints=length(cData.cTimelapse.cTimepoint);

    median=data(2).median(position,:);
    m5=data(2).max5(position,:);
    
    plot(cData.plotAxes,1:numTimepoints,m5./median,'color',full(cData.trackingColors(labels(i),1:3)));
    x=find(max(m5./median)==(m5./median));
    y=max(m5./median);
    text(x,y,int2str(labels(i)),'parent',cData.plotAxes,...
        'color',full(cData.trackingColors(labels(i),1:3)),...
        'backgroundColor',[0.7 0.7 0.7]);
end

cData.plotVMarker=plot(cData.plotAxes, [timepoint timepoint], [1 2]);
hold(cData.plotAxes,'off');
end

