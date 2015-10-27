function obj=copyBin(obj,cellObj)
    % copybin --- copies binary image from cell object to region object
    %
    % Synopsis:  obj = copybin (obj, cellobj)
    %
    % Input:     obj = an object of a region class
    %            cellobj = an object of a onecell class
    %
    % Output:    obj = an object of a region class

    % Notes:     This method may not be required.
    obj.Bw=cellObj.Bw;
end