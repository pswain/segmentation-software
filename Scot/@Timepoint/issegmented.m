function segged=issegmented(obj,cellnumber)
    % issegmented --- determines if the input cell number is segmented at this timepoint
    %
    % Synopsis:  segged=issegmented(obj, cellnumber)
    %
    % Input:     obj = an object of a timepoint class
    %            cellnumber = scalar, the number of the cell to be tested
    %
    % Output:    segged = boolean scalar, 1 if the cell is segmented, 0 if
    %            not

    % Notes:     
    %
   cellnumbers=[obj.TrackingData.cells.cellnumber];
   f=find(cellnumbers==cellnumber, 1);
   if isempty(f)
       segged=false;
   else
       segged=true;
   end
end