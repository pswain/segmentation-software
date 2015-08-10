function obj=trackyeast(obj)
% trackyeast --- %tracking function for whole timelapse
%
% Synopsis:  obj = trackyeast(obj)
%
% Input:     obj = an object of a timelapse class
%            
% Output:    obj == an object of a timelapse class

% Notes: Populates the obj.Tracked field and adds cellnumbers to the
%        obj.TrackingData structure
obj.Tracked=zeros(size(obj.Segmented));
if isempty(obj.TimePoints)
  obj.TimePoints=size(obj.Segmented,3); 
end
%In the TrackingData.cells structure - all cells start with zero
%in the cell number field. They have a trackingnumber field 
%defined that identifies each cell uniquely.
highest=size(obj.TrackingData(1).cells,2);%highest cell number in the first time point
%First time point - cell numbers = tracking numbers
for cell=1:highest
        obj.TrackingData(1).cells(cell).cellnumber=obj.TrackingData(1).cells(cell).trackingnumber;
end
obj.Tracked(:,:,1)=obj.Segmented(:,:,1);
%loop through the remaining timepoints assigning the number of the nearest
%cell in the previous timepoint to each cell.
for t=2:obj.TimePoints
   disp(strcat('Tracking time point ',num2str(t)));%COMMENT THIS LINE FOR SPEED
   if t<=size(obj.TrackingData,2)%this if statement allows interrupted/incomplete segmentations to be tracked
     [obj highest]=obj.tracktimepoint(t);
   end
end

end
       
                 
      