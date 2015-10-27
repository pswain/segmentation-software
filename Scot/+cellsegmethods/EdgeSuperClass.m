classdef EdgeSuperClass<cellsegmethods.Segmethods    

methods
    function [oneCellObj fieldHistory]=initializeFields(obj, oneCellObj)
        % initializeFields --- Populates the OneCell fields required to run several, related cell segmentation methods based on Canny edge detection
        %
        % Synopsis:  oneCellobj = initializeFields(obj, oneCellObj)   
        %                        
        % Input:     obj = an object of a cellsegmethods class
        %            oneCellObj = an object of a OneCell class
        %
        % Output:    oneCellobj = an object of a OneCell class
        
        % Notes: This superclass was written to share this method between 
        %        several subclasses that require edge images. Calculates 
        %        images and other fields as required by the method object,
        %        which should be an instance of a subclass of this class.
        %        Populates the requiredFields and/or requiredImages 
        %        properties of the subclass object to determine the fields 
        %        needed. Avoids unnecessary calculations by first checking 
        %        if each field has already been created
        
	  fieldHistory=struct('methodobj', {},'levelobj', {}, 'fieldnames',{});
        %Most of the image fields are copied from a portion of region object
        %fields.
        if size(obj.requiredImages,1)>0 
            
            %ThisCell
            if any(strcmp('ThisCell', obj.requiredImages))                                   
               if ~isfield(oneCellObj.RequiredImages,'ThisCell')
                   %First run the initializeFields method of the region
                   %segmentation method - this will make sure that the Bin
                   %field is present in oneCellObj.Region.RequiredImages -
                   %that field is needed by the makeThisCell method.
                   %If this is run during an initial timelapse segmentation
                   %it will do nothing because the fields are already
                   %present.
                   [oneCellObj.Region fieldHistory2]=oneCellObj.Region.SegMethod.initializeFields(oneCellObj.Region);
                   if ~isempty(fieldHistory2)%a method object has been used by the initializeFields method of the region object
                       fieldIndex=size(fieldHistory,2)+1;
                       fieldHistory(fieldIndex).fieldnames='ThisCell';
                       fieldHistory=obj.addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex);
                   end
                   oneCellObj=obj.makeThisCell(oneCellObj);                    
               end
            end         
            
            %Bounding box field
            if any(strcmp('BoundingBox', obj.requiredFields))
               if isfield(oneCellObj.RequiredImages,'ThisCell')
                   props=regionprops(oneCellObj.RequiredImages.ThisCell,'BoundingBox');
                   oneCellObj.RequiredFields.BoundingBox=ceil(props.BoundingBox);
               end                   
            end
            
            
            %EdgeImage
            if any(strcmp('EdgeImage', obj.requiredImages))
                if ~isfield(oneCellObj.RequiredImages,'EdgeImage')
                    oneCellObj=oneCellObj.makeEdgeImage(oneCellObj.Region);            
                end
            end
            
            %OuterRemoved and/or OuterImage
            if any(strcmp('OuterRemoved', obj.requiredImages)) || any(strcmp('OuterImage', obj.requiredImages))                         
                if ~isfield(oneCellObj.RequiredImages,'OuterRemoved')
                    [oneCellObj.RequiredImages.OuterRemoved oneCellObj.RequiredImages.OuterImage]=obj.DeleteOuter(oneCellObj.RequiredImages.EdgeImage, oneCellObj.RequiredImages.ThisCell);
                end
            end
                       
            %AbsEdgeImage
            if any(strcmp('AbsEdgeImage', obj.requiredImages))
                if ~isfield(oneCellObj.RequiredImages,'AbsImage')
                    if ~isfield(oneCellObj.RequiredImages,'AbsEdgeImage')
                       oneCellObj.Region=oneCellObj.Region.makeAbsEdge; 
                    end
                    oneCellObj=oneCellObj.makeAbsEdge(oneCellObj.Region);
                end
            end
            
            %OuterRemovedAbs
            if any(strcmp('OuterRemovedAbs', obj.requiredImages))                             
                if ~isfield(oneCellObj.RequiredImages,'OuterRemovedAbs')
                    [oneCellObj.RequiredImages.OuterRemovedAbs oneCellObj.RequiredImages.OuterImageAbs]=obj.DeleteOuter(oneCellObj.RequiredImages.AbsEdgeImage, oneCellObj.RequiredImages.ThisCell);
                end
            end
            
            %Small Watershed
            if any(strcmp('SmallWatershed', obj.requiredImages))                                   
               if ~isfield(oneCellObj.RequiredImages,'SmallWatershed')
                   %First run the initializeFields method of the region
                   %segmentation method - this will make sure that the
                   %Watershed field is present in oneCellObj.Region.RequiredImages -
                   %that field is needed by the makeThisCell method.
                   %If this is run during an initial timelapse segmentation
                   %it will do nothing because the fields are already
                   %present.
                   [oneCellObj.Region fieldHistory2]=oneCellObj.Region.SegMethod.initializeFields(oneCellObj.Region);
                   if ~isempty(fieldHistory2)%a method object has been used by the initializeFields method of the region object
                       fieldIndex=size(fieldHistory,2)+1;
                       fieldHistory(fieldIndex).fieldnames='SmallWatershed';
                       fieldHistory=obj.addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex);
                   end
                   oneCellObj=oneCellObj.makeSmallWatershed(oneCellObj.Region);
               end
            end
            
            %Watershed
            if any(strcmp('Watershed', obj.requiredImages)) %the Watershed image from the region                                  
               if ~isfield(oneCellObj.RequiredImages,'Watershed')
                   %First run the initializeFields method of the region
                   %segmentation method - this will make sure that the
                   %Watershed field is present in oneCellObj.Region.RequiredImages -
                   %that field is needed by the makeThisCell method.
                   %If this is run during an initial timelapse segmentation
                   %it will do nothing because the fields are already
                   %present.
                   
                   [oneCellObj.Region fieldHistory2]=oneCellObj.Region.SegMethod.initializeFields(oneCellObj.Region);
                   if ~isempty(fieldHistory2)%a method object has been used by the initializeFields method of the region object
                       fieldIndex=size(fieldHistory,2)+1;
                       fieldHistory(fieldIndex).fieldnames='Watershed';
                       fieldHistory=obj.addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex);
                   end
                   oneCellObj.RequiredImages.Watershed=oneCellObj.Region.RequiredImages.Watershed;
               end
            end  
        end
        
        %Now create SE field if necessary
        
        if size(obj.requiredFields,1)>0
            
            %SE - structuring element
            if any(strcmp('SE', obj.requiredFields))
                oneCellObj.RequiredFields.SE=strel('disk',obj.parameters.disksize);
            end
            

            
            
        end       
        
        
            

    end
end


methods (Static)
function oneCellObj=makeThisCell(oneCellObj)
    % makeThisCell --- creates the ThisCell property of OneCell object
    %
    % Synopsis:  oneCellObj = makeThisCell(oneCellObj)
    %                        
    % Input:     oneCellObj = an object of a OneCell class
    %
    % Output:    oneCellObj = an object of a OneCell class

    % Notes:     For cells in regions that are not split (by watershed),
    %            simply copies the Bin property of the region. For
    %            split cells returns an image showing only the white pixels
    %            of the region's Bin image that are in this cell's catchment
    %            basin
    
    if oneCellObj.CatchmentBasin==0
        oneCellObj.RequiredImages.ThisCell=oneCellObj.Region.RequiredImages.Bin(:,:,end);
    else
        oneCellObj.RequiredImages.ThisCell=false(size(oneCellObj.Region.Target));
        binImage=oneCellObj.Region.RequiredImages.Bin(:,:,end);
        oneCellObj.RequiredImages.ThisCell(oneCellObj.Region.RequiredImages.Watershed==oneCellObj.CatchmentBasin)=binImage(oneCellObj.Region.RequiredImages.Watershed==oneCellObj.CatchmentBasin);
    end

end
function [outerDeleted outerImage]=DeleteOuter(edgeImage,thisCell)
    % DeleteOuter --- finds the outermost object in an input edge image
    %
    % Synopsis:  [OuterDeleted OuterImage] = DeleteOuter (edgeImage, thisCell)
    %                        
    % Input:     edgeImage = binary 2d matrix
    %            thisCell = binary 2d matrix, approximation to the cell shape, defines centre point 
    %
    % Output:    outerDeleted =  image in which the outermost object of edgeImage has been removed
    %            outerImage = binary 2d matrix, image showing only the outermost object of edgeImage

    % Notes:     
    
    %If statement to avoid errors in case of a blank input image
    if any(edgeImage)==0
         outerDeleted=edgeImage;
         outerImage=edgeImage;
         return
    end
    objs=regionprops(edgeImage,'BoundingBox','Image','PixelList');                   
    [closest outerImage meandist]=cellsegmethods.FindOuter.furthestFromCentroid(edgeImage, thisCell);
    outerDeleted=edgeImage;
    outerDeleted(outerImage==1)=0;
end

end
end
    


