function showMessage(handles,message,colour)

if nargin==1
    h=guidata(gcf);
    colour=[.5 1 .5];
        if isfield (h,'infobox')
           set(h.infobox,'String',handles,'ForegroundColor',colour);
        else
            disp(handles)
        end
else
    if nargin==2 && isstruct(handles)
        colour=[.5 1 .5];
    end
    set(handles.infobox,'String',message,'ForegroundColor',colour);
end
drawnow;