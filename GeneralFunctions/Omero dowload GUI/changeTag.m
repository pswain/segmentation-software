function changeTag(dropDownHandle, event, thirdInput)
handles=guidata(get(dropDownHandle,'Parent'));
data=handles.data;


value=get(dropDownHandle,'Value');
tagStrings=get(dropDownHandle,'String');
tagString=tagStrings{value};
matched=strmatch(tagString,data(:,4));
set(handles.dsTable,'Data',data(matched,:));


end