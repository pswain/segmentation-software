function cellSelected(table, h, anotherinput)

gui=get(table,'parent');
handles=guidata(gui);
handles.selectedIds=[];
data=get(table,'data');
handles.selectedIds=data(h.Indices(:,1),1);
handles.selectedIds=[handles.selectedIds{:}];

guidata(gui,handles);
end