function [trackingdata]=getTrackingData(obj,regionObj)
    % changeSE --- returns a trackingdata structure for the current object
    %
    % Synopsis:  trackingdata = getTrackingData(obj, regionObj
    %                        
    % Input:     obj= an object of a OneCell class
    %            regionObj = an object of a region class
    %
    % Output:    trackingdata = structure, showing details of segmentation
    %            for this cell.

    % Notes:     
    trackingdata.cellnumber=obj.CellNumber;
    trackingdata.trackingnumber=obj.TrackingNumber;
    trackingdata.method=obj.Method;
    trackingdata.catchmentbasin=obj.CatchmentBasin;
    trackingdata.disksize=obj.SESize;
    trackingdata.erodetarget=obj.ErodeTarget;
    trackingdata.centroidx=obj.CentroidX;
    trackingdata.centroidy=obj.CentroidY;
    trackingdata.region=[obj.TopLeftx obj.TopLefty obj.xLength obj.yLength regionobj.Depth];
    trackingdata.contours=obj.Contours;
    trackingdata.deleteoutermethod=obj.DeleteOuterMethod;                 
end