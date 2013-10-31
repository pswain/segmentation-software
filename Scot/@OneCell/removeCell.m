function obj=removeCell(obj)
    % removeCell --- removes a cell from a data set
    %
    % Synopsis:  obj = removeCell(obj)
    %                        
    % Input:     obj = an object of a OneCell class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     
    
    obj.Result=false(size(obj.EdgeImage));
    obj.FullSizeResult=false(obj.ImageSize);
    obj.Fluorescence=NaN;
    obj.Success=0;
end