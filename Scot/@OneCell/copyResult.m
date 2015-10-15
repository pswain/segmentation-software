function obj=copyResult(obj,tracked)
    % copyResult --- copies relevant data from an input segmentation result image to the results fields of a OneCell object
    %
    % Synopsis:  obj = copyResult (obj, tracked)
    %                        
    % Input:     obj= an object of a OneCell class
    %            tracked = 2d matrix, result of segmentation and tracking for a timepoint
    %
    % Output:    obj= an object of a OneCell class

    % Notes:     Call when creating a OneCell object for editing of
    %            segmentation results. obj.ThisCell and obj.Success must be defined before
    %            calling
            obj.Result=false(size(obj.ThisCell));
            obj.FullSizeResult=false(size(tracked));
            if obj.Success==1%the cell has been segmented previously            
                obj.Result(tracked(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1)==obj.CellNumber)=1;
                obj.FullSizeResult=false(size(tracked(:,:,1)));
                obj.FullSizeResult(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1)=obj.Result;              
                obj.Fluorescence=mean(obj.FlImage(obj.FullSizeResult==1));              
            end
        end