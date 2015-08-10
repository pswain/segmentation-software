function obj = segmentTimelapse(obj)
% segmentTimelapse --- identifies cells within timelapse data using one of
%                      a range of methods
%
% Synopsis:  [obj]=segmentTimelapse(obj)
%
% Input:     obj = an object of a timelapse class
%           
%
% Output:    obj = an object of a timelapse class

% Notes:    Segmentation code. Finds pixels representing cell interiors in 
%           timelapse data. These are recorded in a 3d binary array.
%           obj.Segmented(t).Result(y,x,TN), where:
%           t = timepoint
%           x,y = the coordinates
%           TN is the tracking number of the cell, a unique identifier at this timepoint.
%           Also populates obj.Bin3d, a ed
%           image (y,x,t) used to identify regions to process independently
%           within the larger image.
%
%           Currently assumes that images for segmentation have the string
%           '*DIC*' in their name and that there is a single DIC image at
%           each time point (ie not a z stack).

%currently only one method implemented:
DICimages = dir(fullfile(obj.Moviedir,'*DIC*'));
obj.TimePoints=size(DICimages,1);
obj.Bin3d=false(obj.ImageSize(2), obj.ImageSize(1), obj.TimePoints);
%Process now depends on the method provided in the defaults structure
switch obj.Defaults.method
   case {'edges','edges+contours'}
       %loop through the timepoints calling the segmentation constructor of
       %timepoint to build up the segmented stack
       for t=1:size(DICimages,1)      
            DIC=imread(strcat(obj.Moviedir,'/',DICimages(t).name));
            timepoint=timepoint3(DIC,obj,t,obj.Defaults);         
            obj.Segmented(t).Result=timepoint.Segmented;
            obj.Bin3d(:,:,t)=timepoint.Bin;
            if t==1
                obj.TrackingData=timepoint.TrackingData;
            else
                obj.TrackingData(t)=timepoint.TrackingData;
            end
            disp(num2str(t));
       end
   case 'contours'
   %in this case the first time point only is segmented using
   %the edge detection methods. Subsequently the image from the
   %previous time point is used as a starting point for the
   %segmentation.
   %First segment timepoint 1.
   DIC=imread(strcat(obj.Moviedir,'/',DICimages(t).name));
   timepoint=timepoint3(DIC,obj,1,obj.Defaults);
   obj.Segmented(:,:,1)=timepoint.Segmented;
   obj.Tracked(:,:,1)=timepoint.Segmented;
   obj.Bin3d(:,:,1)=timepoint.Bin;
   obj.TrackingData(1)=timepoint.TrackingData;
   %Then loop through the remaining timepoints, using contours only
   %to segment:
   for t=2:size(DICimages,1);
       DIC=imread(strcat(obj.Moviedir,'/',DICimages(t).name));
      %THIS IS NOT FINISHED...
   end
end

end