function [outData ] = dataToExcel( filename, timelapse )
%dataToExcel Exports data to an Excel worksheet
%   Exports a selection of the data to an excel worksheet
data = timelapse.cTimelapse.extractedData;
    fields = fieldnames(data(1));
    outData = [];
    for i=1:(numel(fields)-2)
        temp = data(1).(fields{i})(1,:);
        fields(i)
        if isempty(outData)
            outData = temp;
            outData = [fields{i}, outData];
        else
            outData = [outData; fields{i}, temp];
        end
    end

    %xlswrite(filename,outData);
end

