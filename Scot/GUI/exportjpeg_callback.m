function exportjpeg_callback(source, eventdata,handles)

    % exportjpeg_callback --- Saves the currently-diplayed graph as a jpeg file
    %
    % Synopsis:  exportjpeg_callback (source, eventdata,handles)
    %                        
    % Input:     source = handle to the calling uicontrol object
    %            eventdata = structure, details of calling event
    %            handles = structure, holds all gui and timelapse information
    %
    % Output:    

    % Notes:	 Executes when the exportgraph button is clicked.


    handles=guidata(handles.gui);
    set(handles.selectPoint,'Visible','Off');
    [name path]=uiputfile('*.jpg','SingleCellsOverTime - save plot',[handles.timelapse.Name ' ' handles.currentDataField]);
    a=strfind(name,'.jpg');
    if ~isnumeric(name)
        f=getframe(handles.plot);
        imwrite(f.cdata,[path name],'jpg');       
        showMessage('Saved graph as .jpg image file.');
    else%A numeric name will be 0 - indicates the cancel button was pressed
        showMessage('No filename was entered - graph not exported');
    end
    
    
    
    %Reset the gui
    set (handles.exportjpeg,'Value',0);
    set(handles.selectPoint,'Visible','Off');
    guidata(handles.gui,handles);