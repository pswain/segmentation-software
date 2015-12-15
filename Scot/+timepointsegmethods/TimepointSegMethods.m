classdef TimepointSegMethods<MethodsSuperClass
    properties
        resultImage='Result'
    end
    methods (Abstract)
        [timepointObj]=run(obj,timepointObj);
        timepointObj=initializeFields(obj, timepointObj);
    end
    methods (Static)
        function timepointObj=recordCells(timepointObj, history)
            % recordCells --- creates a record in the timelapse object of cells segmented at the timepoint level
            %
            % Synopsis:  timepointObj=recordCells(timepointObj)
            %                        
            % Input:     timepointObj = an object of a Timepoint class
            %
            % Output:    timepointObj = an object of a Timepoint class
            %            
            % Notes:     This writes the data from timepointObj.Result into
            %            the .Result field of the parent timelapse object.
            %            It also records an entry for each cell in the
            %            timelapse.TrackingData structure. Before calling
            %            this function timepointObj.Timelapse.CurrentCell
            %            should be set (normall to 1).
  
            
            
            tl=timepointObj.Timelapse;%just to make some of the following lines shorter - copy the handle of the timelapse object
            for n=1:size(timepointObj.Result,3)
                %Get the centroid position
                props=regionprops(timepointObj.Result(:,:,n),'Centroid','BoundingBox');
                if ~isempty(props)
                oneSlice=timepointObj.Result(:,:,n);
                tl.Result(tl.CurrentFrame).timepoints(tl.CurrentCell).slices=sparse(oneSlice);
                    %Write the trackingdata entry
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).cellnumber=0;%Prior to tracking all cellnos are 0
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).trackingnumber=tl.CurrentCell;
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).methodobj=[history.methodobj];
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).levelobj=[history.levelobj];
                    %Delete subsequent (preallocated) entries in the history - cell
                    %segmentation is complete
                    history.levelobj(timepointObj.Timelapse.HistorySize+1:end)=[];
                    history.methodobj(timepointObj.Timelapse.HistorySize+1:end)=[];                                 
                    %Record the centroid position and region
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).centroidx=props(1).Centroid(1);
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).centroidy=props(1).Centroid(2);
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).region=ceil(props(1).BoundingBox);
                    %Record the segmenting level object
                    tl.TrackingData(tl.CurrentFrame).cells(tl.CurrentCell).segobject=timepointObj.ObjectNumber;

                    tl.CurrentCell=tl.CurrentCell+1;

                
                end
                
            end
            
           
        end
    end
end