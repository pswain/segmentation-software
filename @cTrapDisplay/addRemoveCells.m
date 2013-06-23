function addRemoveCells(cDisplay,subAx,trap)

cp=get(subAx,'CurrentPoint');
cp=round(cp);
Cx=cp(1,1);
Cy=cp(1,2);
cellPt=[Cx Cy];
timepoint = floor(get(cDisplay.slider,'Value'));
if strcmp(get(gcbf,'SelectionType'),'alt')
    disp(['remove circle at ', num2str([Cx,Cy])]);
    selection='remove';
else
    disp(['add circle at ', num2str([Cx,Cy])]);
    selection='add';
end
method='hough';
cDisplay.cTimelapse.addRemoveCells(cDisplay.cCellVision,timepoint,trap,selection,cellPt, method, cDisplay.channel)
slider_cb(cDisplay);

