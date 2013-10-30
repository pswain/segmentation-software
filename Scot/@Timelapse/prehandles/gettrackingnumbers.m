function trackingnumbers=gettrackingnumbers(obj,cellnumber)
% gettrackingnumbers --- returns the trackingnumbers corresponding to an input cellnumber
%
% Synopsis:  trackingnumbers=gettrackingnumbers(obj,cellnumber)
%
% Input:     obj = an object of a timelapse class
%            cellnumber = scalar, the cellnumber to find trackingnumbers
%            for
%
% Output:    trackingnumbers = vector, trackingnumber entry for each
%                              timepoint

% Notes:    %allows changes to be made to the trackingdata entries for the same
            %cell (same cellnumber) at several timepoints. If the
            %cellnumber is not present at a given timepoint that entry is
            %zero
            
trackingnumbers=zeros(1,size(obj.TrackingData,2));
for t=1:size(obj.TrackingData,2)%loop through the timepoints
   cellnos=[obj.TrackingData(t).cells.cellnumber];
   tracknos=[obj.TrackingData(t).cells.trackingnumber];
   matches=cellnos==cellnumber;
   if any (matches)
        trackingnumbers(t)=tracknos(matches);
   end
end
end