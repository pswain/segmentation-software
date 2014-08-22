function updatePlot( cData )
%UPDATEPLOT Update the plotted data
%   Only call this function when a change is made to either the data or the
%   list of cells to be plotted
%
%   Extracted data is stored seperately from cell data, in order of
%   original arrangement. Need to find index of current cell in original
%   plot
[allTrapIDs,allCellIDs]=find(cData.cTimelapse.cellsToPlot); %Cells which have data
[selectedTrapIDs, selectedCellIDs]=find(cData.cellsToPlot); %Cells to be plotted in the cData window
timepoint=get(cData.timepointSlider,'value');
data = cData.cTimelapse.extractedData;
cla(cData.plotAxes);
hold(cData.plotAxes,'on');
%================================
%Needs new logic
%1. CellsToPlot Row gives cell ID, column gives trap number
%2. extractedData.trapNum is the trap number of the trap for each cell &
%cellNum is the cell ID of that cell. This is much easier than the nonsense
%I had to go through and on the whole I prefer it.
%=================================
for i=1:length(selectedCellIDs)
    [extractedDataCell,~]=find(allCellIDs==selectedCellIDs(i));
    numTimepoints=length(cData.cTimelapse.cTimepoint);

    median=data(2).median(extractedDataCell,:);
    m5=data(2).max5(extractedDataCell,:);
    
    a=plot(cData.plotAxes,1:numTimepoints,m5./median,'color',full(cData.trackingColors(selectedCellIDs(i),1:3)));
    set(a,'buttondownfcn',{@clickLabel,cData,extractedDataCell});
    if extractedDataCell==cData.highlightedCell
        set(a,'linewidth',1.5);
    end
    %Print the line label at the max value
    x=find(max(m5./median)==(m5./median));
    y=max(m5./median);
    text(x,y,int2str(selectedCellIDs(i)),'parent',cData.plotAxes,...
        'color',full(cData.trackingColors(selectedCellIDs(i),1:3)),...
        'backgroundColor',[0.7 0.7 0.7],...
        'buttondownfcn',{@clickLabel,cData,extractedDataCell});
end


for i=1:length(cData.cTimelapse.cTimepoint)
    if cData.upslopes(cData.highlightedCell,i)==1
        up=plot(cData.plotAxes,[i i], [1 2],'linestyle','--','color',[1 0 0]);
        set(up,'buttondownfcn',{@clickUpslopes,cData,i});
    end
    
    if cData.downslopes(cData.highlightedCell,i)==1
        down=plot(cData.plotAxes,[i i], [1 2], 'linestyle','--','color',[0 1 0]);
        set(down,'buttondownfcn',{@clickDownslopes,cData,i});
    end
end
cData.plotVMarker=plot(cData.plotAxes, [timepoint timepoint], [1 2]);
if ~isempty(cData.keypoint)
    plot(cData.plotAxes, [cData.keypoint cData.keypoint], [1 2],'linestyle',':','color',[0 0 0]);
end
hold(cData.plotAxes,'off');
end

function clickLabel(~,~,cData,label)
    cData.highlightedCell=label;
    updatePlot(cData)
end

function clickUpslopes(~,~,cData,timepoint)
    cData.upslopes(cData.highlightedCell,timepoint)=0;
    updatePlot(cData);
end

function clickDownslopes(~,~,cData,timepoint)
    cData.downslopes(cData.highlightedCell,timepoint)=0;
    updatePlot(cData);
    saveData(cData, cData.filepath);
end