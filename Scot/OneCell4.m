classdef OneCell4<OneCell
    properties   
     
    end

    methods   
        function obj=OneCell4(timelapseObj, frame, nearestFrame, trackingnumber)
            
            % OneCell4 --- constructor for OneCell4 object, creates a onecell object for a cell for which segmentation has failed
            %
            % Synopsis:  obj = OneCell4(timelapseObj, frame, nearestFrame, trackingnumber)
            %
            % Input:     timelapseObj = an object of a timelapse class
            %            frame = integer, the current timepoint
            %            nearestFrame = the nearest timepoint at which the cell was segmented
            %            trackingnumber = the trackingnumber of the cell at the nearestFrame
            
            %Notes - Use the alternative class OneCell3 for segmenting new
            %        cells.            
            
            obj.Timelapse=timelapseObj;
            obj.Success=0;
            obj.CellNumber=timelapseObj.TrackingData(nearestFrame).cells(trackingnumber).cellnumber;
            obj.TrackingNumber=[];
            region=timelapseObj.TrackingData(nearestFrame).cells(trackingnumber).region;
            obj.Result=false(region(4), region(3));
            obj.DisplayResult=obj.Result;
            %create the target image
            filename=[timelapseObj.ImageFileList(timelapseObj.Main).directory '/' timelapseObj.ImageFileList(timelapseObj.Main).file_details(frame).timepoints.name];
            image=imread(filename);                     
            obj.Target=image(region(1):region(1)+region(3)-1,region(2):region(2):region(4)-1);
            %Define the region
            obj.Region=Region4(timelapseObj, frame, trackingnumber, nearestFrame);
            %set the segmentation method object number to the one that was used for the successful cell at the other timepoint
            methodNo=obj.Timelapse.TrackingData(nearestFrame).cells(trackingnumber).methodobj(end);
            obj.SegMethod=obj.Timelapse.methodFromNumber(methodNo);
            obj=obj.SegMethod.initializeFields(obj);            
        end
    end  
end

    
    
    



