function obj=initialiseFields(obj,methodobj,regionObj)
    % InitialiseFields --- Populates the onecell fields required to run the input cell segmentation method
    %
    % Synopsis:  obj = InitialiseFields(obj, cellsegmethodobj, regionObj)   
    %                        
    % Input:     obj = an object of a OneCell class
    %            cellsegmethodobj = an object of a cellsegmethods class
    %            regionObj = an object of a region class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     Calculates images and other fields as required by the
    %            input method object. Uses the requiredFields property of
    %            cellsegmethods class to determine the fields needed.
    %            Avoids unnecessary calculations by first checking if each
    %            field has already been created
        
    %loop through the required fields
    if size(methodobj.requiredFields,1)>0
        for f=1:size(methodobj.requiredFields,1)
            switch char(methodobj.requiredFields(f))
                case 'EdgeImage'
                    if ~isfield(obj.RequiredImages','EdgeImage')
                        obj=obj.makeEdgeImage(regionObj);
                    end                    
                case 'OuterRemoved'
                    if isempty (methodobj.parameters.DeleteOuterMethod);
                        methodobj.parameters.DeleteOuterMethod=1;
                    end
                    if methodobj.parameters.DeleteOuterMethod==1
                        if ~isfield(obj.RequiredImages,'ThisCell')
                                obj=obj.makeThisCell(regionObj);
                        end
                    end
                    %need obj.EdgeImage for the calculations that follow
                    if isempty(obj.EdgeImage)
                        obj=obj.makeEdgeImage(regionObj);
                    end                    
                    if isempty (obj.CatchmentBasin)&& methodobj.parameters.DeleteOuterMethod~=1%There is no need to send onecell image to DeleteOuter
                        if isempty(obj.DeleteOuter)%if the object doesn't exist need to create it                            
                            obj.DeleteOuter=calculateimages.DeleteOuter(obj.EdgeImage, methodobj.parameters.DeleteOuterMethod);
                        else
                            obj.DeleteOuter.checkMethod(obj.EdgeImage,methodobj.parameters.DeleteOuterMethod);%will recalculate the image only if a different delete outer method is required
                        end
                    else%this is a split region - need to send onecell to the delete outer class
                        if isempty(obj.DeleteOuter)
                            obj.DeleteOuter=calculateimages.DeleteOuter(obj.EdgeImage, methodobj.parameters.DeleteOuterMethod,obj.ThisCell);
                        else
                            obj.DeleteOuter.checkMethod(obj.EdgeImage,methodobj.parameters.DeleteOuterMethod,obj.ThisCell);
                        end
                    end
                case 'OuterImage'%OuterImage is a field of the obj.OuterRemoved object - initialised in the same way and at the same time as above
                    if isempty (methodobj.parameters.DeleteOuterMethod);
                        methodobj.parameters.DeleteOuterMethod=1;
                    end
                    if methodobj.parameters.DeleteOuterMethod==1
                        if isempty(obj.ThisCell)
                                obj=obj.makeThisCell(regionObj);
                        end
                    end
                    %need obj.EdgeImage for the calculations that follow
                    if isempty(obj.EdgeImage)
                        obj=obj.makeEdgeImage(regionObj);
                    end                    
                    if isempty (obj.CatchmentBasin)&& methodobj.parameters.DeleteOuterMethod~=1%There is no need to send onecell image to DeleteOuter
                        if isempty(obj.DeleteOuter)%if the object doesn't exist need to create it                            
                            obj.DeleteOuter=calculateimages.DeleteOuter(obj.EdgeImage, methodobj.parameters.DeleteOuterMethod);
                        else
                            obj.DeleteOuter.checkMethod(obj.EdgeImage,methodobj.parameters.DeleteOuterMethod);%will recalculate the image only if a different delete outer method is required
                        end
                    else%this is a split region - need to send onecell to the delete outer class
                        if isempty(obj.DeleteOuter)
                            obj.DeleteOuter=calculateimages.DeleteOuter(obj.EdgeImage, methodobj.parameters.DeleteOuterMethod,obj.ThisCell);
                        else
                            obj.DeleteOuter.checkMethod(obj.EdgeImage,methodobj.parameters.DeleteOuterMethod,obj.ThisCell);
                        end
                    end

                case 'AbsEdgeImage'
                    if isempty(obj.AbsEdgeImage)
                        if isempty(regionObj.AbsImage)
                           regionObj=regionObj.makeAbsEdge; 
                        end
                        obj=obj.makeAbsEdge(regionObj);
                    end      

                case 'OuterRemovedAbs'
                    if isempty (methodobj.parameters.DeleteOuterMethod);
                        methodobj.parameters.DeleteOuterMethod=1;
                    end
                    if methodobj.parameters.DeleteOuterMethod==1%Method 1 requires obj.ThisCell to be calculated
                        if isempty(obj.ThisCell)
                            obj=obj.makeThisCell(regionObj);
                        end
                    end
                    %need obj.AbsEdgeImage for the calculations that follow
                    if isempty(obj.AbsEdgeImage)
                        if isempty(regionObj.AbsImage)
                           regionObj=regionObj.makeAbsEdge; 
                        end
                        obj=obj.makeAbsEdge(regionObj);
                    end                                     
                    if isempty (obj.CatchmentBasin) && methodobj.parameters.DeleteOuterMethod~=1%There is no need to send onecell image to DeleteOuter
                        if isempty(obj.DeleteOuterAbs)%if the object doesn't exist need to create it                            
                            obj.DeleteOuterAbs=calculateimages.DeleteOuter(obj.AbsEdgeImage, methodobj.parameters.DeleteOuterMethod);
                        else
                            obj.DeleteOuterAbs.checkmethod(obj.AbsEdgeImage,methodobj.parameters.DeleteOuterMethod);%will recalculate the image only if a different delete outer method is required
                        end
                    else%this is a split region - need to send onecell to the delete outer class
                        if isempty(obj.DeleteOuterAbs)
                            obj.DeleteOuterAbs=calculateimages.DeleteOuter(obj.AbsEdgeImage, methodobj.parameters.DeleteOuterMethod,obj.ThisCell);
                        else
                            obj.DeleteOuterAbs.checkmethod(obj.AbsEdgeImage,methodobj.parameters.DeleteOuterMethod,obj.ThisCell);
                        end
                    end
                case 'SE'%Note if SE is in the requiredFields parameter then the disksize parameter must also be set
                    if isempty(obj.SE)
                            obj.SE=strel('disk',methodobj.parameters.disksize);
                    end
                case 'SmallWatershed'
                    if isempty(obj.SmallWatershed)
                        obj=obj.makeSmallWatershed(regionObj);
                    end
                case 'ThisCell'
                    if isempty(obj.ThisCell)
                        obj=obj.makeThisCell(regionObj);
                    end
                case 'BoundingBox'
                    if isempty(obj.TopLeftThisCellx)
                        obj=obj.makeBoundingBox(regionObj);
                    end
            end
        end
    end
end