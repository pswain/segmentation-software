%Spot model method written by Christos Josephides
classdef NumSpots<extractdata.ExtractData
    methods
        function obj=NumSpots(varargin)
            obj.parameters = struct;
            obj.parameters.channel = 'GFP';%Label for the data to be measured, to be displayed in the GUI
            obj.parameters.chidentifier = 'GFP';%string that occurs only in filenames belonging to the desired channel
            obj.parameters.sections=1;%integer, number of sections at each timepoint that contain obj.parameters.chidentifier in their filename
            obj.parameters.measuredsections=[1];%integer vector, the sections to use as the source of the data
            obj.parameters.interval=5;%Time interval between images in this channel (in min)
            obj.parameters.numspots=1;%Number of spots (0, 1 or 2) expected. The method will return a probability that there are obj.parameters.numspots spots in the data
            obj.parameters.sizeratio=.25;%The expected ratio between the area of the spot and the area of the cell
            obj.parameters.iterations=50;%Number of times to run the spotModelSelect algorithm
            
            obj=obj.changeparams(varargin{:});
            %The datafield is the name of the field in timelapse.Data that
            %the results will be stored in. It is defined after the call to
            %changeparams because it depends on one of the object
            %parameters.
            switch obj.parameters.numspots
                case 0
                    spotString='no spots';
                case 1
                    spotString='1 spot';
                case 2
                    spotString='2 spots';
            end
                obj.datafield=[obj.parameters.channel ' ' 'Probability of ' spotString];

        end
        
        function timelapseObj=run(obj, timelapseObj)
            % run --- records the number of spots in each cell at each timepoint in timelapseObj.Data
            %
            % Synopsis:  timelapseObj = run (obj, timelapseObj)
            %
            % Input:     obj = an object of class NumSpots
            %            timelapseObj = an object of a timelapse class
            %
            % Output:    timelapseObj = an object of a timelapse class

            % Notes:    Adds to the Data property of timelapseObj. Measures
            %           number of spots (from 1 to 2 in the z sections
            %           defined by obj.parameters.sections for the channel
            %           defined in obj.parameters.chidentifier.
            
            highest=timelapseObj.gethighest;
            obj.datafield=[obj.parameters.chidentifier '_' 'NumSpots'];
            %Write to stored version of this method object
            timelapseObj=setMethodObjField(timelapseObj, obj.ObjectNumber, 'datafield', obj.datafield);
            %Create result array
            if ~ischar(obj.parameters.channel)
                chan=char(obj.parameters.channel);
            else
                chan=obj.parameters.channel;
            end
            %Populate the image file list for this channel
            %And get the index to the list for this channel
            [timelapseObj index]=timelapseObj.addImageFileList(char(obj.parameters.channel),timelapseObj.Moviedir,char(obj.parameters.chidentifier),obj.parameters.sections);

            %result is a 2d array. Initialize the array (this will
            %wipe any previous data created on this channel with this
            %method
            %Array dimensions: (cellnumber, timepoint)
            %The size statement on this line allows different channels
            %to have different numbers of timepoints - some can skip
            %timepoints.
            timelapseObj.Data.(obj.datafield)=zeros(highest,size(timelapseObj.ImageFileList(index).file_details,2));  
            %Loop through the timepoints
            for t=1:size(timelapseObj.ImageFileList(index).file_details,2)
                showMessage(['Finding spots in time point ' num2str(t)]);
                fullSizeTarget=imread([timelapseObj.Moviedir,filesep timelapseObj.ImageFileList(index).file_details(t).timepoints.name]);
                %Loop through the cells at this timepoint
            	for c=1:size(timelapseObj.TrackingData(t).cells,2)
                    showMessage(['Cell ' num2str(c)]);
                    cellnumber=timelapseObj.TrackingData(t).cells(c).cellnumber;%This will be the row number of the data entries
                    %This method requires an image from the target channel
                    %that is tightly bound by a rectangle around the
                    %segmented cell. Use the bounding box of the cell.
                    if isreal (cellnumber)%ie if this cell hasn't been deleted - entry would be nan
                            fullSizeResult=timelapseObj.Result(t).timepoints(c).slices;
                            props=regionprops(full(fullSizeResult),'BoundingBox');
                            x=ceil(props(1).BoundingBox(1));
                            y=ceil(props(1).BoundingBox(2));
                            xlength=props(1).BoundingBox(3);
                            ylength=props(1).BoundingBox(4);
                            target=fullSizeTarget(y:y+ylength-1, x:x+xlength-1);
                            trials=zeros(obj.parameters.iterations,3);
                            for n=1:obj.parameters.iterations
                                trials(n,:) = extractdata.spotModelSelect(target,obj.parameters.sizeratio,'display');                              
                            end
                            timelapseObj.Data.(obj.datafield)(c, t)=mean(trials(:,obj.parameters.numspots));
                    end
                end

            
            
            
            end
    end
    end
end





