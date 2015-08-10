function obj=segmentCell(obj,regionObj)
    % segmentCell --- tries the range of available methods to find interior pixels of a single cell
    %
    % Synopsis:  obj = segmentCell(obj, regionObj)
    %                        
    % Input:     obj = an object of a OneCell class
    %            regionObj = an object of a region class
    %
    % Output:    obj = an object of a OneCell class

    % Notes:     Populates the obj.Result and obj.Success and obj.Method
    %            fields. Also populates all other fields necessary for the 
    %            segmentationmethods used (eg edge detected images).
    
    %            Methods and the order in which they are used are specified
    %            before calling this function in the
    %            timelapseObj. field. These methods are encoded
    %            in subclasses of the Segmethods superclass.
    obj.Success=0;
    order=regionObj.Defaults.order;%names of methods in the order in which they will be tried
    n=1;
    while obj.Success~=1 && n<=size(order,1)
        %If an object of the appropriate method class is not already
        %present in the Timelapse.ObjectStruct field then create it by
        %calling getobj. This will call the constructor of the class
        %defined by order(n) and populate the requiredFields and parameters
        %properties.
        method=obj.Timelapse.getobj('cellsegmethods',char(order(n)));
        obj.initialiseFields(method,regionObj);%populate the required fields of the OneCell object
        if any (ismember(method.requiredFields, 'Region'))
            obj.Result=method.run(obj,regionObj);
        else
            obj.Result=method.run(obj);
        end      
        [obj.Success centroid]=obj.Timelapse.ObjectStruct.cellsegmethods.(char(order(n))).testSuccess(obj.Result);
        obj.CentroidX=centroid(1);
        obj.CentroidY=centroid(2);
        n=n+1;
    end
    

    %Refine result by fitting a shape this is specified by regionObj.Defaults
    if obj.Success==1
        classString=char(order(n-1));
        disp(classString);
        obj.Method=classString;
        if strcmp(regionObj.Defaults.contours.fit,'convhull');
            props=regionprops(obj.Result,'ConvexImage','BoundingBox','Area');
            convresult=false(size(obj.Result));
            [a b]=max([props.Area]);%want the convex hull of the largest object only
            topleftx=ceil(props(b).BoundingBox(1));
            toplefty=ceil(props(b).BoundingBox(2));
            lengthx=props(b).BoundingBox(3);
            lengthy=props(b).BoundingBox(4);
            convresult(toplefty:toplefty+lengthy-1,topleftx:topleftx+lengthx-1)=props(b).ConvexImage;
            obj.Result=convresult;
        end
        %Refine result using active contours if this is specified by regionObj.Defaults
        if strcmp(regionObj.Defaults.method,'edges+contours')==1 || strcmp(regionObj.Defaults.method,'contours')==1
            if isempty(obj.CatchmentBasin)%this is a single cell, not split by watershed
                contResult=chanvese(regionObj.Target,obj.Result,regionObj.Defaults.contours.iterations,regionObj.Defaults.contours.mu,regionObj.Defaults.contours.method,0);
                contResult=imresize(contResult,size(regionObj.Target));
                contResult=contResult&obj.Result;%this improves the result when the contour has shrunk the mask - but makes it worse if it has grown
                contResult=imfill(contResult,'holes');
                obj.Result=contResult;
            else%the region has been divided by the watershed function
                if isempty(obj.SmallResult)
                    obj.SmallResult=obj.makeSmall(obj.Result);
                end
                if isempty(obj.SmallTarget)
                    obj.SmallTarget=obj.makeSmall(regionObj.Target);
                end
                smallContResult=chanvese(obj.SmallTarget,obj.SmallResult,regionObj.Defaults.contours.iterations,regionObj.Defaults.contours.mu,regionObj.Defaults.contours.method,0);
                smallContResult=imresize(smallContResult,size(obj.SmallTarget));
                smallContResult=smallContResult&obj.SmallResult;%this improves the result when the contour has shrunk the mask - but makes it worse if it has grown           
                smallContResult=imfill(smallContResult,'holes');
                obj=obj.placeResultInRegion(smallContResult);
            end                 
        end
        obj.Result=method.largestOnly(obj.Result);
    end
end 