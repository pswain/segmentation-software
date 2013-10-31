function obj=segmenttimelapse(obj)
% segmenttimelapse --- identifies cells within timelapse data
%
% Synopsis:  [obj]=segmenttimelapse(obj)
%
% Input:     obj = an object of a timelapse class
%           
%
% Output:    obj = an object of a timelapse class

% Notes:    Segmentation code. Finds pixels representing cell interiors in 
%           timelapse data. These are recorded in a 3d image
%           obj.Segmented(y,x,t). Pixel values in obj.Segmented are unique
%           for each cell, but only at a given timepoint (ie cells are
%           labelled 1, 2, 3 etc at each timepoint). These numbers are the
%           trackingnumber of each cell. Also populates obj.Bin3d, a ed
%           image (y,x,t) used to identify regions to process independently
%           within the larger image.
%
%           Currently assumes that images for segmentation have the string
%           '*DIC*' in their name and that there is a single DIC image at
%           each time point (ie not a z stack).

%Start Fiji (used for some image processing functions)
%First set up the classpath using the Miji script - need to find the
%directory in which the fiji application directory is located. It is two
%levels up from the current one.
thispath=mfilename('fullpath');
split=strread(thispath,'%s', 'delimiter','/');
twofromend=size(char(split(end-1)),2)+size(char(split(end)),2)+2;
thatpath=thispath(1:end-twofromend);
addpath([thatpath '/Fiji.app/scripts']);
Miji;
DICimages = dir(fullfile(obj.Moviedir,'*DIC*'));
obj.Segmented=zeros(512,512,size(DICimages,1));%COULD ALSO GET THE IMAGE SIZE FROM THE FIRST FILE
obj.Bin3d=false(size(obj.Segmented));
obj.TimePoints=size(DICimages,1);
%Process now depends on the method provided in the defaults structure
switch obj.Defaults.method
   case {'edges','edges+contours'}
       %loop through the timepoints calling the segmentation constructor of
       %timepoint to build up the segmented stack
       for t=1:size(DICimages,1)      
            DIC=imread(strcat(obj.Moviedir,'/',DICimages(t).name));
            timepoint=timepoint3(DIC,obj.Defaults);
            obj.Segmented(:,:,t)=timepoint.Segmented;
            obj.Bin3d(:,:,t)=timepoint.Bin;
            if t==1
                obj.TrackingData=timepoint.TrackingData;
            else
                try
                obj.TrackingData(t)=timepoint.TrackingData;
                catch
                    disp('error here - disimilar structures - debug and check segmentation method');
                end
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
   timepoint=timepoint3(DIC,obj.Defaults);
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