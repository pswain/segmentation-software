classdef MeanFluorescence<extractdata.ExtractData
    methods
        function obj=MeanFluorescence(varargin)
            obj.parameters = struct;
            obj.parameters.channel = 'GFP';%Label for the data to be measured, to be displayed in the GUI
            obj.parameters.chidentifier = 'GFP';%CHANGE BACK TO 'GFP' AND FIX GENERATION OF SECTION NAMESstring that occur s only in filenames belonging to the desired channel
            obj.parameters.sections=1;%integer, number of sections at each timepoint that contain obj.parameters.chidentifier in their filename
            obj.parameters.measuredsections=[1];%integer vector, the sections to use as the source of the data
            obj.parameters.interval=5;%Time interval between images in this channel (in min)
            obj=obj.changeparams(varargin{:});
            %The datafield is the name of the field in timelapse.Data that
            %the results will be stored in. It is defined after the call to
            %changeparams because it depends on one of the object
            %parameters.
            obj.datafield=[obj.parameters.channel 'MeanFluorescence'];

        end
    
        function timelapseObj=run(obj, timelapseObj)
            % run --- records mean fluorescence in each cell at each timepoint in timelapseObj.Data
            %
            % Synopsis:  timelapseObj = run (obj, timelapseObj)
            %
            % Input:     obj = an object of class MeanFluorescence
            %            timelapseObj = an object of a timelapse class
            %
            % Output:    timelapseObj = an object of a timelapse class

            % Notes:    Adds to the Data property of timelapseObj. Measures
            %           mean fluorescence in the z sections defined by
            %           obj.parameters.sections for the channel defined in
            %           obj.parameters.channel. This method requires files
            %           saved using specific filenames in the folder with
            %           path timelapseObj.Moviedir. Sample filename:
            %           exp_000001_GFP_002.png (GFP image, section 2,
            %           timepoint 1 of experiment 'exp')
            highest=timelapseObj.gethighest;
            obj.datafield=[obj.parameters.channel 'MeanFluorescence'];
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
                    %initialize a matrix to take the fluorescence data for
                    %this timepoint
                    flData=zeros(timelapseObj.ImageSize(2), timelapseObj.ImageSize(1), size(obj.parameters.sections,2));
                    %Loop through the measured sections reading the relevant file into the flData array
                    for s=1:size(obj.parameters.sections,2)
                       section=obj.parameters.measuredsections(s);
                       try
                       flData(:,:,s)= imread([timelapseObj.Moviedir,filesep timelapseObj.ImageFileList(index).file_details(t).timepoints(section).name]);
                       catch
                           showMessage(['File ' timelapseObj.ImageFileList(index).file_details(t).timepoints(section).name ' may not be an image file']);
                       end
                    end
                    %Create a 2d mean image for all the sections
                    mean2d=mean(flData,3);
                    %Loop through the cells at this timepoint assigning
                    %their mean fluorescence value to obj.Data
                   
                    for c=1:size(timelapseObj.TrackingData(t).cells,2)
                        trackingnumber=timelapseObj.TrackingData(t).cells(c).trackingnumber;
                        cellnumber=timelapseObj.TrackingData(t).cells(c).cellnumber;
                        if ~isnan (cellnumber)%ie if this cell hasn't been deleted - entry would be nan
                            fullSizeResult=timelapseObj.Result(t).timepoints(trackingnumber).slices;
                            timelapseObj.Data.([chan 'MeanFluorescence'])(cellnumber, t)=mean(mean2d(fullSizeResult));
                        end                        
                    end
                end            
        end
    end
end