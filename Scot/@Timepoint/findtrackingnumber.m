function [trackingnumber]=findtrackingnumber(obj,cellnumber)
    % findtrackingnumber --- returns the tracking number for an input cell number at this timepoint
    %
    % Synopsis:  trackingnumber=findtrackingnumber(obj,cellnumber) 
    %
    % Input:     obj = an object of a timepoint class
    %            cellnumber = scalar, the number of the cell
    %
    % Output:    trackingnumber = scalar, the cell's tracking number

    % Notes:     Trackingnumber is the index to the entry of the cell in
    %            the obj.TrackingData structure. Also the value of the
    %            pixels representing the cell in timelapse.Segmented.
    %            Unlike cellnumber, trackingnumber varies for the same
    %            cell at different timepoints. Returns zero if the cell is
    %            not segmented or tracked at the current timepoint.
    %
   cellnumbers=[obj.TrackingData.cells.cellnumber];
   trackingnumber=find(cellnumbers==cellnumber);
   if isempty(trackingnumber)
       trackingnumber=0;
   end
end