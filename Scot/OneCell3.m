classdef OneCell3<OneCell
    properties   
    end

    methods   
        function obj=OneCell3(regionObj,catchmentbasin, history)
            % onecell3 --- constructor for onecell object, segments cell
            %
            % Synopsis:  obj = onecell3(regionObj, catchmentbasin)
            %            obj = onecell3(regionObj, 0)
            %
            % Input:     regionObj = an object of a region class
            %            catchmentbasin = integer, the catchment basin in which to attempt segmentation
            %
            % Output:    obj= object of class onecell3

            % Notes:     This constructor performs segmentation on single
            %            cell. If the region has not been split by
            %            watershed (ie is a single cell) then input 2
            %            should be zero. Only fields required for all cases
            %            where the region is split are defined here. All
            %            other fields required for segmentation are
            %            initialised by the InitialiseFields method.
            
            %First define images necessary for segmentation if the cell is split
            %Left undefined if it's a single cell.
            if catchmentbasin>0
                obj.CatchmentBasin=catchmentbasin;%catchment basin is left empty if the region has not been split
                obj=obj.makeThisCell(regionObj);
                %define bounding box of watershedded region - required by all split cell segmentation methods
                splitcells=regionprops(obj.RequiredImages.ThisCell,'BoundingBox','Centroid');
                if ~isempty(splitcells)
                    %obj.TopLeftThisCellx=ceil(splitbb(1));
                    %obj.TopLeftThisCelly=ceil(splitbb(2));
                    %obj.xThisCellLength=splitbb(3);
                    %obj.yThisCellLength=splitbb(4);
                    obj.CentroidX=splitcells.Centroid(1)+regionObj.TopLeftx;
                    obj.CentroidY=splitcells.Centroid(2)+regionObj.TopLefty;
                    
                else
                    %obj.TopLeftThisCellx=1;
                    %obj.TopLeftThisCelly=1;
                    %obj.xThisCellLength=size(regionObj.Target,2);
                    %obj.yThisCellLength=size(regionObj.Target,1);
                    obj.CentroidX=splitcells(1).Centroid(1)+regionObj.TopLeftx;
                    obj.CentroidY=splitcells(1).Centroid(2)+regionObj.TopLefty;
                end
            else
                obj.CatchmentBasin=0;
                obj.CentroidX=size(regionObj.Target,2)/2+regionObj.TopLeftx;
                obj.CentroidY=size(regionObj.Target,1)/2+regionObj.TopLefty;
            end
            obj.Timelapse = regionObj.Timelapse;
            obj.ObjectNumber=obj.Timelapse.NumObjects;
            obj.TrackingNumber=0;
            obj.Timelapse.NumObjects=obj.Timelapse.NumObjects+1;
            obj.Region=regionObj;    
            obj.TopLeftx=regionObj.TopLeftx;
            obj.TopLefty=regionObj.TopLefty;
            obj.xLength=regionObj.xLength;
            obj.yLength=regionObj.yLength;
            obj.RunMethod=obj.Timelapse.getobj('runmethods','RunCellSegMethods');
            obj.Target=regionObj.Target;
            %Now send to the segmentation function.
            obj=obj.RunMethod.run(obj,regionObj, history);
        end
    end  
end

    
    
    



