function runDownload (table, h, thirdArgument)
disp('stop here');
handles=guidata(gcf);
if ~isfield(handles,'destination')
    %can add a control to define a destination field from the gui later
    destination=uigetdir;
end
if ~isfield(handles,'selectedIds')
    tableData=get(table,'data');
    
end
for n=1:length(handles.selectedIds)
    %Create a folder for each dataset
    %Then set obj.DownloadPath
    %then run obj.downloadFiles
end