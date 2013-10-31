function  exportdata_callback(source, eventdata,handles)

    % exportdata_callback --- Saves the data extracted from segmented timelapse in a .csv file
    %
    % Synopsis:  exportdata_callback (source, eventdata,handles)
    %                        
    % Input:     source = handle to the calling uicontrol object
    %            eventdata = structure, details of calling event
    %            handles = structure, holds all gui and timelapse information
    %
    % Output:    

    % Notes:	 Executes when the exportdata button is clicked.
    
    handles=guidata(handles.gui);
    [name path]=uiputfile('*.csv','SingleCellsOverTime - export data',[handles.timelapse.Name ' data file']);
    a=strfind(name,'.csv');
    dsNames=fields(handles.timelapse.Data);%Names of the datasets
    if ~isnumeric(name)
        fullName=[path name];
        dataFile=fopen(fullName,'w');%Then can write to logfile later using fprintf(dataFile,'string goes here');
        fprintf(dataFile,'%s','Single Cells Over Time - data file');
        fprintf(dataFile,'\r\n');
        today=date;
        fprintf(dataFile,'%s',today);
        fprintf(dataFile,'\r\n');
        %Loop through the data sets
        for dataSet=1:size(fields(handles.timelapse.Data),1)           
           field=dsNames{dataSet};
           fprintf(dataFile,'%s',field);
           fprintf(dataFile,'\r\n');
           %Create cell number column headings, with an empty cell first -
           %for the timepoint number column
           fprintf(dataFile,'%s',',');
           for c=1:size(handles.timelapse.Data.(field),1)
                fprintf(dataFile,'%s', ['Cell number ' num2str(c) ',']);
           end
           fprintf(dataFile,'\r\n');

           %Loop through the timepoints
           for t=1:size(handles.timelapse.Data.(field),2)
               fprintf(dataFile,'%s',['Time point ' num2str(t) ',']);
               %Loop through the cells
               for c=1:size(handles.timelapse.Data.(field),1)
                fprintf(dataFile,'%d', handles.timelapse.Data.(field)(c,t));
                fprintf(dataFile,'%s', ',');
               end
               fprintf(dataFile,'\r\n');
           end
        end
        fclose(dataFile);
        showMessage('Measured data exported.');
    else
       showMessage('Data export cancelled.');
    end
    
    %Record any changes to handles - this will allow use of a handles field
    %to record if there have been any changes since the last export
    guidata(handles.gui,handles);