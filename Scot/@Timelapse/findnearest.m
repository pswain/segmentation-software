function [nearesttimepoint trackingdata]=findnearest(obj,cellnumber,timepoint)
% findnearest --- returns the nearest timepoint (forward or back) at which
%                 an input cellnumber is segmented 
%
% Synopsis:  [nearesttimepoint x y trackingnumber]=findnearest(obj,cellnumber,timepoint)
%            
% Input:     obj = an object of a timelapse class
%            cellnumber = scalar, number of the cell to find
%            timepoint = scalar, the current timepoint, will find the nearest appearence of the cell to this timepoint
%
% Output:    nearesttimepoint = scalar, the nearest timepoint at which the input cellnumber is segmented
%            trackingdata = structure, the entry in obj.TrackingData.cells for the found cell

% Notes:    called by timelapse editing software after a change to a
%           timepoint (or a cell number) where the selected cell is not
%           segmented. Looks for the nearest timepoint (forwards or back)
%           at which the cell is segmented and returns it. The data related
%           to this nearesttimepoint can then be used to initialise cell
%           and region objects.
testindex=timepoint;
found=false;
count=1;
%the following loop returns the nearest timepoint for which the cell number
%has been segmented
while found==false
    upindex=testindex+count;
    downindex=testindex-count;
        
    if upindex>obj.TimePoints && downindex<1
        nearesttimepoint=0;
        trackingdata=struct;
        break%the cell is not found in this data set
    end
    if size(obj.TrackingData,2)>=upindex
        upLogIndex=[obj.TrackingData(upindex).cells.cellnumber]==cellnumber;
    else
        upLogIndex=0;
    end
    if any(upLogIndex)
       nearesttimepoint=upindex;
       found=true;
       trackingdata=obj.TrackingData(nearesttimepoint).cells(upLogIndex);       
    else
        if downindex>0
           if size(obj.TrackingData,2)>=downindex
           downLogIndex=[obj.TrackingData(downindex).cells.cellnumber]==cellnumber;
           else
               downLogIndex=0;
           end
           if any(downLogIndex)
               nearesttimepoint=downindex;
               found=true;
               trackingdata=obj.TrackingData(nearesttimepoint).cells(downLogIndex);       
           end
        end
    end  
        count = count+1;
end%of while loop

if found==false
   trackingdata=[];
   nearesttimepoint=0;
end



end