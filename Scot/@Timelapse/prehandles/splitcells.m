function obj=splitcells(obj,cellnumber,tp)
% splitcells --- divides the record of a cell at an input timepoint into two cells with different cell numbers
%
% Synopsis:  obj=splitcells(obj,cellnumber,tp)
%
% Input:     obj = an object of a timelapse class
%            cellnumber = scalar, the cellnumber of the cell to split
%            tp = scalar, the timepoint at which to split the cell
%
% Output:    obj = an object of a timelapse class

% Notes:     Function to split up two cells that have incorrectly been 
%            given the same cell numbers at different time points. Input tp
%            is the timepoint at which the split occurs, eg if tp==3, the
%            original cell number is used for time points 1:3 while
%            timepoints 4:end have a new cell number

%Properties to change:
%obj.TrackingData
%obj.Tracked
%obj.Data
%Lengths
%First define the new cellnumber to assign to some cells
cellinfo=[obj.TrackingData.cells];
allcellnums=[cellinfo.cellnumber];
highest=max(allcellnums);
%obj.TrackingData
trackingnumbers=gettrackingnumbers(obj,cellnumber);
for n=tp+1:size(obj.TrackingData,2)%loop from input timepoint to the end of the timelapse
  if trackingnumbers(n)~=0
    obj.TrackingData(n).cells(trackingnumbers(n)).cellnumber=highest+1;
  end
end
%Tracked
obj.Tracked(obj.Tracked(:,:,tp+1:size(obj.TrackingData,2))==cellnumber)=highest+1;
%Data
%Add an extra row to obj.Data
obj.Data(highest+1,:,:)=nan;%(cell number,channel,timepoint)
%copy values from the cellnumber entries
obj.Data(highest+1,:,tp+1:size(obj.TrackingData,2))=obj.Data(cellnumber,:,tp+1:size(obj.TrackingData,2));
%Then delete the entries under cellnumber
obj.Data(cellnumber,:,tp+1:size(obj.TrackingData,2))=nan;
%Lengths
%Recalculate the data lengths (number of time points with a segmented result)
issegmented=isnan(obj.Data(cellnumber,1,:))==0;
obj.Lengths(cellnumber)=sum(issegmented);
issegmented2=isnan(obj.Data(highest+1,1,:))==0;
obj.Lengths(highest+1)=sum(issegmented2);
end