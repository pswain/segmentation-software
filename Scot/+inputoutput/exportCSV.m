function exportCSV (tl,fullPath)
    % exportXl --- Saves the .Data field in the input Timelapse object to a csv file
    %
    % Synopsis:  exportCSV (tl,fullPath)
    %            exportCSV (tl)
    %
    % Input:     tl = an object of a Timelapse subclass
    %            fullPath = string, the full path to the output file or double, a valid .csv file identifier
    %
    % Output:    Written to .csv file

    % Notes:     
    if nargin<2
        [name path]=uiputfile('*.csv','SingleCellsOverTime - export data',[tl.Name ' data file']);
        fullPath=[path name];
        if name==0;
            showMessage('Data export cancelled.');
            return;
        end
        dataFile=fopen(fullPath,'w');%Then can write to file later using fprintf(dataFile,'string goes here');
        fprintf(dataFile,'%s','Single Cells Over Time - data file');
        fprintf(dataFile,'\r\n');
        today=date;
        fprintf(dataFile,'%s',today);
        fprintf(dataFile,'\r\n');
    else
        if isnumeric(fullPath)
            %File identifier is input - used eg for writing multiple
            %timelapse datasets in batch
            dataFile=fullPath;
        else
            dataFile=fopen(fullPath,'w');%Then can write to file later using fprintf(dataFile,'string goes here');
            fprintf(dataFile,'%s','Single Cells Over Time - data file');
            fprintf(dataFile,'\r\n');
            today=date;
            fprintf(dataFile,'%s',today);
            fprintf(dataFile,'\r\n');
        end
    end
    dsNames=fields(tl.Data);%Names of the datasets
    %Loop through the data sets
    for dataSet=1:size(fields(tl.Data),1)
        field=dsNames{dataSet};
        fprintf(dataFile,'%s',field);
        fprintf(dataFile,'\r\n');
        %Create cell number column headings, with an empty cell first -
        %for the timepoint number column
        fprintf(dataFile,'%s',',');
        for c=1:size(tl.Data.(field),1)
            fprintf(dataFile,'%s', ['Cell number ' num2str(c) ',']);
        end
        fprintf(dataFile,'\r\n');
        
        %Loop through the timepoints
        for t=1:size(tl.Data.(field),2)
            fprintf(dataFile,'%s',['Time point ' num2str(t) ',']);
            %Loop through the cells
            for c=1:size(tl.Data.(field),1)
                fprintf(dataFile,'%d', tl.Data.(field)(c,t));
                fprintf(dataFile,'%s', ',');
            end
            fprintf(dataFile,'\r\n');
        end
    end
    fclose(dataFile);
    showMessage('Measured data exported.');
        
end

