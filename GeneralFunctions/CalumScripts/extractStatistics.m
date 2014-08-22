function [ outData ] = extractStatistics( data, cellNumber, varargin )
%UNTITLED2 Summary of this function goes here
%  Extract the data for a cell and place it in an array
%  Specify any number of statistics as arguments and 
%  they will be extracted
%  Data must be a .extractedData(i) class

    fields = fieldnames(data);
    outData = [];

    for i=1:(numel(fields)-2)
        if any(strcmp(varargin, fields{i}))
            temp = data.(fields{i})(cellNumber,:);
            
            if isempty(outData)
                outData = temp;
            else
                outData = [outData; temp];
            end
        end
    end


end

