function addRemoveCells(cDisplay,subAx,trap)

cp=get(subAx,'CurrentPoint');
cp=round(cp);
Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = floor(get(cDisplay.slider,'Value'));
if strcmp(get(gcbf,'SelectionType'),'alt')
    disp(['remove circle at ', num2str([Cx,Cy])]);
    selection=0;
else
    disp(['add circle at ', num2str([Cx,Cy])]);
    selection=1;
end
method='hough';
cDisplay.cTimelapse.addRemoveCells(cDisplay.cCellVision,timepoint,trap,selection,cellPt, method, cDisplay.channel)

%

pts=[];
cellCenters=[cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellCenter];
cellCenters=reshape(cellCenters,2,length(cellCenters)/2)';

pts(:,1)=cellCenters(:,1);
pts(:,2)=cellCenters(:,2);
if size(pts,1)
    aPointMatrix = repmat(cellPt,size(pts,1),1);
    D = (sum(((aPointMatrix-pts).^2), 2)).^0.5;

%     D = pdist2(pts,cellPt,'euclidean');
    [minval loc]=min(D);
    cDisplay.cTimelapse.cellsToPlot(trap,cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(loc))=selection;
end



%
slider_cb(cDisplay);

