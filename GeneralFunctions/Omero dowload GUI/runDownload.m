function runDownload (table, h, thirdArgument)

handles=guidata(gcf);

%Only download one dataset if handles.singleDs is true
if ~handles.singleDs
    handles.omeroDs=handles.selectedIds;
else
   %User must select a single dataset
   if length(handles.selectedIds)>1
       disp('please select a single dataset');
       return;
   end
   handles.omeroDs=handles.selectedIds;
end
if ~isfield(handles,'destination')
    %can add a control to define a destination field from the gui later
    disp('Select a folder to save the downloaded images');
    destination=uigetdir;
else
    destination=handles.destination;
end
tableData=get(handles.dsTable,'data');
if ~isfield(handles,'selectedIds')%If no datasets have been selected - just download all the datasets in the table  
    handles.selectedIds=[tableData{:,1}];
else
    if isempty(handles.selectedIds)
        handles.selectedIds=[tableData{:,1}];
    end
end


exptNames={};
handles.folder={};

for n=1:length(handles.omeroDs)
    %Get the data for this row of the table (one dataset)
    tableRow=tableData(handles.selectedIds(n)==[tableData{:,1}],:);
    %Create a folder name
    exptName=tableRow{3};
    %Make sure it's unique
    num=0;
    while any (strcmp(exptName,exptNames))
        exptName=[exptName num2str(num)];
    end
    exptNames{n}=exptName;
    
    if ~strcmp(destination(end),filesep)
        destination(end+1)=filesep;
    end
    exptFolder=[destination exptName];
    handles.folder{n}=exptFolder;
    mkdir(exptFolder);
    %Download the data
    handles.obj=handles.obj.downloadDataset(tableRow{1},exptFolder, false);
    
    
    
end
% NEXT LINE TO BE REVISED TO ALLOW MULTIPLE FOLDERS TO BE RETURNED
if length(handles.folder)==1
    handles.folder=exptFolder;
end
guidata(handles.downloadDialog,handles);

%Close the dialog
uiresume;
end