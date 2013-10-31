classdef CellSize<extractdata.ExtractData
    methods
        function obj=CellSize(varargin)
            
                 obj.parameters = struct;
                 %There are no parameters for this method

                 obj.description='CellSize: Returns the number of pixels covered by the cell.';
                 obj.datafield='CellSize';%The datafield is the name of the field in timelapse.Data that
                 %the results will be stored in.
                 obj=obj.changeparams(varargin{:});
                 

        end
    
        function timelapseObj=run(obj, timelapseObj)
            % run --- records CellSize result in each cell at each timepoint in timelapseObj.Data
            %
            % Synopsis:  timelapseObj = run (obj, timelapseObj)
            %
            % Input:     obj = an object of class SimpleSpotFind
            %            timelapseObj = an object of a timelapse class
            %
            % Output:    timelapseObj = an object of a timelapse class

            % Notes:    Adds to the Data property of timelapseObj.
            
            highest=timelapseObj.gethighest;
            %Create result array
            timelapseObj.Data.(obj.datafield)=zeros(highest,timelapseObj.TimePoints);             

            %Loop through the timepoints
            for t=1:timelapseObj.TimePoints
                obj.showProgress(100*t/timelapseObj.TimePoints,'Running CellSize')
                %Loop through the cells segmented at this timepoint
                for c=1:size(timelapseObj.TrackingData(t).cells,2)
                    cellnumber=timelapseObj.TrackingData(t).cells(c).cellnumber;
                    %Size is number of nonzero elements in the result image
                    if ~isnan(cellnumber)%ie the cell has not been deleted
                       timelapseObj.Data.(obj.datafield)(cellnumber,t)=nnz(timelapseObj.Result(t).timepoints(c).slices);                       
                    end
                end
            end             
            obj.showProgress(0,'')
        end
    end
end