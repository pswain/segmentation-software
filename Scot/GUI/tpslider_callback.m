function [handles]=tpslider_callback(source, b, handles)

handles=guidata(handles.gui);
position=round(get(source,'Value'));
switch handles.mode
    case 'SetUp'
        number=handles.trackingnumber;
    case 'Edit'
        number=handles.cellnumber;
end
handles=changeCell(handles, number,position);
guidata(handles.gui,handles);

