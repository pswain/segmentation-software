function obj=getBw(obj,bin)
    % getBw --- copies the correct part of input binary image to obj.RequiredImages.Bin
    %
    % Synopsis:  obj = getBw (obj, bin)
    %
    % Input:     obj = an object of a region class
    %            bin, 2d logical matrix, binary image showing rough location and shape of cells
    %
    % Output:    obj = an object of a region class 

    % Notes:     Only the largest object within the bounding box in the
    %            timepoint.Bin image should be present in
    %            region.RequiredImages.Bw.
    
    %initialise obj.Bw
    localbin=bin(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1);
    if any(localbin(:))
        props=regionprops(localbin,'Image','BoundingBox');
        b=vertcat(props.BoundingBox);
        imgsize=size(localbin);
        a=b(:,1)==0.5 & b(:,2)==0.5 & b(:,3)==imgsize(2) & b(:,4)==imgsize(1);%a is now a logical index to the correct image
        if max(a(:))==0%This may occur if the bounding box doesn't match the image - eg if the cell wasn't segmented at this timepoint and the gui is using the bb from the nearest timepoint at which the cell was segmented
            
            
            sizeofbb=b(:,3).*b(:,4);
            [biggestsize biggest]=max(sizeofbb);
            x=ceil(b(biggest,1));
            y=ceil(b(biggest,2));
            if isfield(obj.RequiredImages,'Bin')
                obj.RequiredImages.Bin(:,:,end+1)=false(size(localbin));
                obj.RequiredImages.Bin(y:y+b(4)-1,x:x+b(3)-1,end)=props(biggest).Image;
            else
                obj.RequiredImages.Bin=false(size(localbin));
                obj.RequiredImages.Bin(y:y+b(4)-1,x:x+b(3)-1)=props(biggest).Image;
            end
        else
            if isfield(obj.RequiredImages,'Bin')
                obj.RequiredImages.Bin(:,:,end+1)=props(a).Image;
            else
                obj.RequiredImages.Bin=props(a).Image;
            end
        end
    else
        %There are no white pixels in localbin - no need to look for the
        %largest object.
        if isfield(obj.RequiredImages,'Bin')
            obj.RequiredImages.Bin(:,:,end+1)=localbin;
        else
            obj.RequiredImages.Bin=localbin;
        end
    end
end