function [region trackingnumber]=findregion(obj,centx,centy)
    % findregion --- returns the region details of the first segmented cell that the input coordinates are in the same region as
    %
    % Synopsis:  [region trackingnumber]=findregion(obj, centx, centy) 
    %
    % Input:     obj = an object of a timepoint class
    %            centx = x coordinate (eg of a cell centroid)
    %            centy = y coordinate (eg of a cell centroid)
    %
    % Output:    region = 5 element vector, specifies region details: [topleftx toplefty xlength ylength depth (used in imhmin function for watershed)]
    %            trackingnumber = scalar, tracking number of the first cell in the region
    
    % Notes:     If the input point is not in a recorded region but is in 
    %            an object of the bin image - returns a region array with
    %            depth 1 (default). The returned tracking number is zero.
    %            If the point is not in any object of the bin image -
    %            returns an empty region array and a zero for the tracking
    %            number
    %
    centx=round(centx);
    centy=round(centy);
    regions=[obj.TrackingData.cells.region];
    numcells=size(obj.TrackingData.cells,2);
    regions=reshape(regions,5,numcells);
    regionsindex=centx>=regions(1,:)&centx<=regions(1,:)+regions(3,:) & centy>=regions(2,:) & centy<=regions(2,:)+regions(4,:);

    if any (regionsindex)%ie is the point within any recorded region
    regionindex=find(regionsindex, 1 );%finds the first 1 in the logical array regionsindex
    region=obj.TrackingData.cells(regionindex).region;
    trackingnumber=regionindex;
    else
    %the region has not been recorded as containing any segmented
    %cells. Use the obj.Bin image to see if it is within an object
    %in which no cells were successfully segmented.
        if obj.Bin(centy,centx)==1
            props=regionprops(obj.Bin,'BoundingBox');
            bb=vertcat(props.BoundingBox);
            %then same as above - regionsindex
            regionsindex=centx>=bb(:,1)&centx<=bb(:,1)+bb(:,3) & centy>=bb(:,2) & centy<=bb(:,2)+bb(:,4);
            if any(regionsindex)
                regionindex=find(regionsindex,1);
                region=[ceil(bb(regionindex,1)) ceil(bb(regionindex,2)) bb(regionindex,3) bb(regionindex,4) 1];
                trackingnumber=0;
            else
                region=[];
                trackingnumber=0;
            end
       else
            region=[];%return an empty array - indicates the point is in no region of bin.
            trackingnumber=0;
       end
    end
end%of findregion function