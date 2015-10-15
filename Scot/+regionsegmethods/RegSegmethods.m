classdef RegSegmethods<MethodsSuperClass
    properties
         resultImage='Result';

    end
    methods (Abstract)
        result=run(obj, regionObj);
        regionObj=initializeFields(obj, regionObj);               
    end
    methods (Static)
        function regionObj=recordCells(regionObj, history)
            % recordCells --- creates a record in the timelapse object of cells segmented at the region level
            %
            % Synopsis:  regionObj=recordCells(regionObj)
            %                        
            % Input:     regionObj = an object of a region class
            %
            % Output:    regionObj = an object of a region class
            %            
            % Notes:     This writes the data from regionObj.Result into
            %            the .Result field of the parent timelapse object.
            %            It also records an entry for each cell in the
            %            timelapse.TrackingData structure.            

            tl=regionObj.Timelapse;%just to make some of the following lines shorter - copy the handle of the timelapse object
            %Preallocate the trackingnumbers array
            numPreviousCells=size(regionObj.TrackingNumbers,2);
            regionObj.TrackingNumbers(numPreviousCells+1:numPreviousCells+1+size(regionObj.Result,3))=uint16(0);            
            for n=1:size(regionObj.Result,3)
                oneSlice=false(tl.ImageSize(2), tl.ImageSize(1));
                oneSlice(regionObj.TopLefty:regionObj.TopLefty+regionObj.yLength-1,regionObj.TopLeftx:regionObj.TopLeftx+regionObj.xLength-1) = regionObj.Result(:,:,n);
                tl.Result(tl.CurrentFrame).timepoints(tl.CurrentCell).slices=sparse(oneSlice);
                tl.Result(tl.CurrentFrame).timepoints(tl.CurrentCell).slices(regionObj.TopLefty:regionObj.TopLefty+regionObj.yLength-1,regionObj.TopLeftx:regionObj.TopLeftx+regionObj.xLength-1) = regionObj.Result(:,:,n);
                %Write the trackingdata entry
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).cellnumber=0;%Prior to tracking all cellnos are 0
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).trackingnumber=tl.CurrentCell;
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).methodobj=[history.methodobj];
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).levelobj=[history.levelobj];
                %Delete subsequent (preallocated) entries in the history - cell
                %segmentation is complete
                history.levelobj(regionObj.Timelapse.HistorySize+1:end)=[];
                history.methodobj(regionObj.Timelapse.HistorySize+1:end)=[];                  

                %Get the centroid position
                props=regionprops(regionObj.Result(:,:,n),'Centroid','BoundingBox');
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).centroidx=props(1).Centroid(1);
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).centroidy=props(1).Centroid(2);
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).region=[regionObj.TopLeftx regionObj.TopLefty regionObj.xLength regionObj.yLength];
                %Record the segmenting level object
                tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).segobject=regionObj.ObjectNumber;

                tl.CurrentCell=tl.CurrentCell+1;

            end
        end
    end
end