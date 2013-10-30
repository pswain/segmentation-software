function selectPoint_callback(source, eventdata,handles)
    handles=guidata(handles.gui);
    showMessage('Select a point on the graph to view/edit segmentation');
    axes(handles.plot);
    dcm=datacursormode;
    h=gcf;
    selection=false;
    %wait until the user clicks somewhere...
    while ~selection
        waitfor(h,'CurrentObject');
        pointinfo=getCursorInfo(dcm);
        if size(pointinfo,2)==1
            pos=pointinfo.Position;
            cellnumber=find(handles.cellhandles==pointinfo.Target);
            frame=find(handles.timelapse.Data.(handles.currentDataField)(cellnumber,:)==pos(2));
            selection=true;
        end
    end
    handles=changeCell(handles, cellnumber, frame);   
    datacursormode off;
    
    guidata(handles.gui,handles);
end