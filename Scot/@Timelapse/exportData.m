function exportData (obj, fullName, datasets)
    % exportData --- saves data extracted from a timelapse as a .csv file
    %
    % Synopsis:  exportData (obj)
    %            exportData (obj, fullName)
    %                        
    % Input:     obj = an object of a Timelapse class
    %            datasets = cell array of strings, names of the datasets to export
    %            fullName = string, full path and filename of file to save
    %
    % Output:    
    
    % Notes:  Currently assumes export of mCherry and GFP mean fluorescence
    %         data - add code to make use of the third input.

    if nargin==1
        [name path]=uiputfile('*.csv','SingleCellsOverTime - choose folder in which to save exported data file','timelapse_data');
        if name~=0
            if exist(path,'dir')==7
                fullName=[path name];
            else
                error('No valid file name entered- data not exported.');
                return  
            end
        else
            error('No file name entered- data not exported.');
            return 
        end
    else
        k=strfind(fullName,'.csv');
        if isempty(k)
            fullName=[fullName '.csv'];
    end
   dataFile=fopen(fullName,'w');%Then can write to logfile later using fprintf(dataFile,'string goes here');
   fprintf(dataFile,'%s','Single Cells Over Time - data file');
   fprintf(dataFile,'\r\n');
   today=date;
   fprintf(dataFile,'%s',today);
   fprintf(dataFile,'\r\n');
   fprintf(dataFile,obj.Moviedir);
   fprintf(dataFile,'\r\n');

   
   dsNames=fields(obj.Data);%Names of the datasets
    %Loop through the data sets
    for dataSet=1:size(fields(obj.Data),1)           
       field=dsNames{dataSet};
       fprintf(dataFile,'%s',field);
       fprintf(dataFile,'\r\n');
       %Create cell number column headings
       for c=1:size(obj.Data.(field),1)
            fprintf(dataFile,'%s', ['Cell number ' num2str(c) ',']);
       end
       fprintf(dataFile,'\r\n');
       %Loop through the timepoints
       for t=1:size(obj.Data.(field),2)
           fprintf(dataFile,'%s',['Time point ' num2str(t) ',']);
           %Loop through the cells
           for c=1:size(obj.Data.(field),1)
            fprintf(dataFile,'%d', obj.Data.(field)(c,t));
            fprintf(dataFile,'%s', ',');
           end
           fprintf(dataFile,'\r\n');
       end
    end
    fclose(dataFile);
    
    


end