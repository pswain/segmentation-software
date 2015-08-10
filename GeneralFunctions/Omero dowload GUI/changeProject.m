function changeProject(dropDownHandle, event, thirdInput)
handles=guidata(get(dropDownHandle,'Parent'));
data=handles.data;


value=get(dropDownHandle,'Value');
projStrings=get(dropDownHandle,'String');
projString=projStrings{value};
matched=strmatch(projString,data(:,2));
set(handles.dsTable,'Data',data(matched,:));


end