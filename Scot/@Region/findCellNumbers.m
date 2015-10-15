function obj=findCellNumbers(obj,tracked)
    % findcellnumbers --- writes the cell numbers within the region to obj.CellNumbers
    %
    % Synopsis:  obj = findcellnumbers (obj, tracked)
    %
    % Input:     obj = an object of a region class
    %            tracked = 2d matrix, image in which segmented and tracked cells are labelled with their cell numbers (eg timelapseobj.Tracked(:,:,timepoint)
    %            
    % Output:    obj = an object of a region class

    % Notes:     %Only finds cells that lie completely within the region - 
    %             ie that have been/should be segmented within the region
    trackedregion=tracked(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1);
    values=unique(trackedregion);
    %Loop to exclude cells that are partly not in the region - ie
    %overlap >1 region.
    for n=2:size(values,1)%  loop through found values. Start at 2 because values(1)==0 - space outside cells
        numintrackedregion=trackedregion==values(n);
        numintracked=tracked==values(n);
        if sum(numintracked(:))==sum(numintrackedregion(:))
            obj.CellNumbers(n)=values(n);
        end

    end
    %remove any remaining zero values
    %cellnumbers(cellnumbers==0)=[];
    obj.CellNumbers(obj.CellNumbers==0)=[];
end