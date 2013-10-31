function obj=measurefluorescence(obj)
    % measureflourescence --- returns measured mean fluorescence data for each cell in the timepoint
    %
    % Synopsis:  obj=measurefluorescence(obj) 
    %
    % Input:     obj = an object of a timepoint class
    %         
    % Output:    obj = an object of a timepoint class

    % Notes:     Measures the fluorescence values for all cells in a
    %            timepoint. Called when changes have been made that affect
    %            more than one cell so result in cells being re-tracked.
    %            Does not currently cope with more than one section or
    %            channel    
    totalCells=max(obj.Segmented(:));
    obj.Data=NaN(totalCells,1);%Data is a 1d array - 1 entry at this timepoint for each cell;
    for i=1:totalCells
        obj.Data(i)=mean(obj.FlImage(obj.Tracked(:,:)==i));
    end
end