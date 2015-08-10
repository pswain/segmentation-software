function [nearesttimepoint,varargout]=findnearest(obj,cellnumber,timepoint)
% findnearest --- returns the nearest timepoint (forward or back) at which
%                 an input cellnumber is segmented 
%
% Synopsis:  [nearesttimepoint]=findnearest(obj,cellnumber,timepoint)
%            [nearesttimepoint x y]=findnearest(obj,cellnumber,timepoint)
%            [nearesttimepoint x y trackingnumber]=findnearest(obj,cellnumber,timepoint)
%
% Input:     obj = an object of a timelapse class
%            cellnumber = scalar, number of the cell to find
%            timepoint = scalar, the current timepoint, will find the
%                        nearest appearence of the cell to this timepoint
%
% Output:    nearesttimepoint = scalar, the nearest timepoint at which the
%                               input cellnumber is segmented
%            x = scalar, x coordinate of the centroid of the cell at
%                timepoint nearesttimepoint
%            y = scalar, y coordinate of the centroid of the cell at
%                timepoint nearesttimepoint
%            trackingnumber = scalar, the tracking number of the cell at
%                             nearesttimepoint

% Notes:    called by timelapse editing software after a change to a
%           timepoint (or a cell number) where the selected cell is not
%           segmented. Looks for the nearest timepoint (forwards or back)
%           at which the cell is segmented and returns it. The data related
%           to this nearesttimepoint can then be used to initialise cell
%           and region objects.
dataline=obj.Data(cellnumber,:);%all the data for this cell number
a=isnan(dataline);
testindex=timepoint;
found=false;
count=1;
%the following loop returns the nearest timepoint for which data has been
%recorded - ie the nearest timepoint at which this cell was
%segmented
%if statement to avoid a possible endless loop:
   if max(a)>0
       while found==false      
            upindex=testindex+count;
            downindex=testindex-count;
            %make sure up and down indices stay within the limits
            if upindex>size(a,2)
            upindex=size(a,2);
            end
            if downindex<1
            downindex=1;
            end
            if a(upindex)==0
               nearesttimepoint=upindex;
               found=true;
            else
               if a(downindex)==0
               nearesttimepoint=downindex;
               found=true;
               end       
            end  
            count = count+1;
       end%of while loop - to find nearest timepoint with data.

       if nargout>1
           cellnumbers=[obj.TrackingData(nearesttimepoint).cells.cellnumber];
           nearestindex=cellnumbers==cellnumber;
           centroidxbb=obj.TrackingData(nearesttimepoint).cells(nearestindex).centroidx;                   
           centroidybb=obj.TrackingData(nearesttimepoint).cells(nearestindex).centroidy; 
           varargout{1}=round(centroidxbb+obj.TrackingData(nearesttimepoint).cells(nearestindex).region(1));
           varargout{2}=round(centroidybb+obj.TrackingData(nearesttimepoint).cells(nearestindex).region(2));
           if nargout>3
               varargout{3}=find(nearestindex);%trackingnumber                        
           end
       end
   else%this cell number hasn't been found anywhere in the data set
        nearesttimepoint=0;
        if nargout>1
            varargout{1}=0;%centroidx
            varargout{2}=0;%centroidy
            if nargout>3
               varargout{3}=0;%trackingnumber                        
            end
        end
   end%of if statment.

end