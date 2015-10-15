classdef SimpleSpotFind<extractdata.ExtractData
    methods
        function obj=SimpleSpotFind(varargin)
            obj.parameters = struct;
            obj.parameters.channel = 'GFP';%Label for the data to be measured, to be displayed in the GUI
            obj.parameters.chidentifier = 'GFP';%string that occurs only in filenames belonging to the desired channel
            obj.parameters.sections=1;%integer, number of sections at each timepoint that contain obj.parameters.chidentifier in their filename
            obj.parameters.measuredsections=[1 2 3];%integer vector, the sections to use as the source of the data
            obj.parameters.interval=5;%Time interval between images in this channel (in min)
            obj.parameters.minarea=20;
            obj.parameters.maxarea=500;
            
            obj.description='SimpleSpotFind method: Fast method for identifying cells in which fluorescence intensity is localized in spots. Returns the sum of the intensities of the brightest five pixels in each cell divided by the median intensity for that cell.';
            
            obj=obj.changeparams(varargin{:});
            %The datafield is the name of the field in timelapse.Data that
            %the results will be stored in. It is defined after the call to
            %changeparams because it depends on one of the object
            %parameters.
            obj.datafield=[obj.parameters.channel 'SimpleSpotFind'];

        end
    
        function timelapseObj=run(obj, timelapseObj)
            % run --- records SimpleSpotFind result in each cell at each timepoint in timelapseObj.Data
            %
            % Synopsis:  timelapseObj = run (obj, timelapseObj)
            %
            % Input:     obj = an object of class SimpleSpotFind
            %            timelapseObj = an object of a timelapse class
            %
            % Output:    timelapseObj = an object of a timelapse class

            % Notes:    Adds to the Data property of timelapseObj.
            
            highest=timelapseObj.gethighest;
            obj.datafield=[obj.parameters.channel 'SimpleSpotFind'];
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
                
                %Temporary line to get batch processing to work
                timelapseObj.ImageFileList(2)=[];
                
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
                for t=1:timelapseObj.TimePoints
                    t
                    
                    %obj.showProgress(100*t/size(timelapseObj.ImageFileList(index).file_details,2),'Running simple spot finder')
                    %initialize a matrix to take the data for
                    %this timepoint
                    spotData=zeros(timelapseObj.ImageSize(2), timelapseObj.ImageSize(1), size(obj.parameters.sections,2));
                    %Loop through the measured sections reading the relevant file into the flData array
                    for s=1:obj.parameters.sections
                       section=obj.parameters.measuredsections(s);
                       try
                       
                       flData(:,:,s)= imread([timelapseObj.Moviedir,filesep timelapseObj.ImageFileList(index).file_details(t).timepoints(section).name]);
                      
                       catch
                           showMessage(['File ' timelapseObj.ImageFileList(index).file_details(t).timepoints(section).name ' may not be an image file']);
                       end
                    end
                    %Create a maximum projection image for all the sections
                    mean2d=max(flData,[],3);                    
                    %mean2d=obj.subtractBackground(mean2d,timelapseObj,t);
                    %Above line commented to avoid zero median values
                                      
                    %Loop through the cells at this timepoint assigning
                    %their spot value
                   
                    for c=1:size(timelapseObj.TrackingData(t).cells,2)
                        
                        
                        trackingnumber=timelapseObj.TrackingData(t).cells(c).trackingnumber;
                        cellnumber=timelapseObj.TrackingData(t).cells(c).cellnumber;      
                        if cellnumber==2 && t==22
                            disp('debug here');
                        end
                        if ~isnan (cellnumber)%ie if this cell hasn't been deleted - entry would be nan
                            if nnz(timelapseObj.Result(t).timepoints(trackingnumber).slices)>5
                                cellpixels=mean2d(timelapseObj.Result(t).timepoints(trackingnumber).slices);
                                [a,ix] = sort(cellpixels(:),'descend');
                                a = a(1:5);
                                sumIntensities=sum(a);%The sum of the top 5 values                            
                                medianResult=double(median(cellpixels));
                               timelapseObj.Data.(obj.datafield)(cellnumber,t)=sumIntensities/medianResult;
                            else%Cell has <6 pixels - above code will give an error
                                timelapseObj.Data.(obj.datafield)(cellnumber,t)=nan;
                            end
                            end
                        end
                            
                                              
                    end
                end  
                %obj.showProgress(0,'')

        end
    end
