classdef CycleTime<extractdata.ExtractData
    methods
        function obj=CycleTime(varargin)
            % CycleTime --- Constructor for a CycleTime object
            %
            % Synopsis:  obj=CycleTime(varargin)
            %
            % Input:     varargin = cell array of parameter name and value pairs in standard Matlab format
            %
            % Output:    obj = an object of type CycleTime

            % Notes:     Creates a method object of type CycleTime and
            %            initiates its parameters.

            obj.parameters = struct;
            obj.parameters.datasource = 'GFPSimpleSpotFind';
            obj.parameters.threshold = .1;
            obj.parameters.interval=5;
          
            %Define user information
            obj.description='CycleTime method: This can be used, for example, to determine the cell cycle stage of a cell expressing a marker that oscillates with the cell cycle, eg Whi5-GFPp in Saccharomyces. This method requrires data to have been recorded from another method (eg recording a nuclear localization value of a cell cycle marker) before it is run. That data is converted to a binary output - either 1 or 0, using a threshold value. Values above the threshold are defined as 1, values below as zero. The method then returns the time that has passed since the value changed from 1 to zero.';
            obj.paramHelp.datasource = 'Parameter: datasource. The name of the field in the data structure holding the underlying data used to calculate times.';
            
            
            
            obj=obj.changeparams(varargin{:});
            %The datafield is the name of the field in timelapse.Data that
            %the results will be stored in. It is defined after the call to
            %changeparams because it depends on one of the object
            %parameters.
            obj.datafield=[obj.parameters.datasource 'CycleTime'];

        end
    
        function timelapseObj=run(obj, timelapseObj)
            % run --- records CycleTime result in each cell at each timepoint in timelapseObj.Data
            %
            % Synopsis:  timelapseObj = run (obj, timelapseObj)
            %
            % Input:     obj = an object of class CycleTime
            %            timelapseObj = an object of a timelapse class
            %
            % Output:    timelapseObj = an object of a timelapse class

            % Notes:    Adds to the Data property of timelapseObj.
            
            highest=timelapseObj.gethighest;
            obj.datafield=[obj.parameters.datasource 'CycleTime'];
            %Write to stored version of this method object
            timelapseObj=setMethodObjField(timelapseObj, obj.ObjectNumber, 'datafield', obj.datafield);
                
            %Result is a 2d array. Initialize the array (this will
            %wipe any previous data created on this channel with this
            %method.
            %Array dimensions: (cellnumber, timepoint)
            %The size statement on this line allows different channels
            %to have different numbers of timepoints - some can skip
            %timepoints.
            thresholded=timelapseObj.Data.(obj.parameters.datasource)-obj.parameters.threshold>=0; 
            a=zeros(size(timelapseObj.Data.(obj.datasource)));
            for c=1:highest%Loop through the cells                
                thisCellThresh=thresholded(c,:);
                exitTimes=find(thisCellThresh);
                for n=1:length(exitTimes)
                    if n==length(exitTimes)
                        lastInd=size(a,2);
                    else
                        lastInd=exitTimes(n+1);
                    end
                    a(exitTimes(n):lastInd)=[0:lastInd-exitTimes(n)];
                end
            end
            timelapseObj.Data.(obj.datafield)=a.*obj.parameters.interval;
            
            

        end
    end
end