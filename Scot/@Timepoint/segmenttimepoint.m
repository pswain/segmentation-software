function obj=segmenttimepoint(obj)
% segmenttimepoint --- segments the input image of the timepoint
%
% Synopsis:  obj=segmenttimepoint(obj)
%            
% Input:     obj = an object of a timepoint class
%            
% Output:    obj = timepoint object (timelapse object is also modified)

% Notes:     This method performs segmentation of the input
%            image and writes the results to the input timelapse
%            object. The timelapse class should be a subclass of handles
%            so its properties can be written to from here. The optional
%            input adjacenttimepoint allows a contours-only based
%            segmentation using the result from the adjacent timepoint
%            as a mask.
           
%populate the required object fields

[obj.EntropyFilt obj.Bin]=yeastentropy(obj.InputImage, 0.5);
obj.ThreshMethod=obj.Defaults.threshmethod;
%Run segmentation methods according to defaults
switch (obj.Defaults.method)
   case {'edges','edges+contours'}
       obj.edgesegment;%performs edge-based segmentation according to the methods specified in obj.Defaults
       %WRITE RESULT TO TIMELAPSE OBJECT HERE
       %timelapseobj.writetimepoint(obj)THIS WRITE METHOD IS NOT YET
       %WRITTEN
   case 'contours'
%          Cells will be segmented using active contour methods using a
%          mask based on segmented data from an adjacent timepoint
       adjacentimage=timelapseobj.Segmented(:,:,adjacenttimepoint);
       obj=obj.contoursegment(adjacentimage);
end
if isfield(obj.TrackingData,'cells')==0%If no cells have been segmented - create a blank trackingdata.cells array - otherwise get an error
   obj.TrackingData.cells.cellnumber=nan;
   obj.TrackingData.cells.trackingnumber=1;
   obj.TrackingData.cells.method=1;
   obj.TrackingData.cells.catchmentbasin=1;
   obj.TrackingData.cells.disksize=2;
   obj.TrackingData.cells.erodetarget=.5;
   obj.TrackingData.cells.centroidx=[1 1];
   obj.TrackingData.cells.centroidy=[1 1];
   obj.TrackingData.cells.region=[1 1 1 1 1];
   obj.TrackingData.cells.contours=[];
   obj.TrackingData.cells.deleteoutermethod=1;
end
end%of segmenttimepoint function