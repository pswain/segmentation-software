classdef Timelapse3<Timelapse
    properties
    end
  
    methods
        function obj=Timelapse3(moviedir,interval,varargin)
            % Timelapse3 --- constructor for timelapse object, segments,tracks and measures timelapse data.
            %
            % Synopsis:  timelapse=Timelapse3(moviedir,interval)
            %            timelapse=Timelapse3(moviedir,interval,varargin)
            %
            % Input:     moviedir = string, path to folder in which images are stored
            %            interval = scalar, time interval between images in minutes
            %            varargin = method packages, class names and
            %            parameters in standard Matlab format, eg
            %            ('runmethods', {order,{'Segmethod_1','Segmethod_2'}, minpixels, 200, maxpixels, 200},'RunTrackMethod',{'TrackMethod','loop_timepoints'}} 
            %
            % Output:    obj= object of class timelapse3
            
            % Notes:     This constructor performs segmentation and
            %            tracking of timelapse data unless there is a
            %            single input - the string 'blank'. In that case
            %            the constructor returns an object with
            %            no properties initialized. This is used by the
            %            copy function (of the LevelObject superclass).
            thispath=mfilename('fullpath');
            k=strfind(thispath,'/');
            thispath=thispath(1:k(end));
            addpath([thispath 'GUI']);
            if ~strcmp (moviedir,'Blank')              
               
                %Copy input properties                       
                if ischar(moviedir)==1
                    obj.Moviedir=moviedir;
                else
                    obj.Moviedir=moviedir{:};
                end
                obj.Interval=interval;
                %Initiate CurrentFrame + CurrentCell properties
                obj.CurrentFrame=1;
                obj.CurrentCell=1;
                %Initialize the PostHistory
                obj.PostHistory=struct('objnumbers',{},'packages',{});

                
                %Populate the SpecifiedParameters structure
                obj.loadparameters(varargin{:})
                obj.ImageSize=[512 512];%THIS NEEDS TO BE MADE GENERIC - WRITE A METHOD TO OPEN THE FIRST IMAGE TO GET THIS INFORMATION
                obj.Name='Timelapse';%WRITE CODE TO GET EXPERIMENT NAME FROM THE LOG FILE FOR THIS
                                
                %Initialize object number, NumObjects and NumLevelObjects fields
                obj.ObjectNumber=1;
                obj.NumObjects=2;
                obj.NumLevelObjects=0;
                %create run method objects - parameters for these have been
                %defined by the call to loadParameters above.
                obj.RunMethod=obj.getobj('runmethods','RunTLSegMethod');
                obj.RunTrackMethod=obj.getobj('runmethods','RunTrackMethod');
                obj.RunExtractMethod=obj.getobj('runmethods','RunExtractMethod');                                       
                %Initialize the LevelObjects property
                obj.LevelObjects=struct;
                %Populate the 'main' property of the image file list - these will be used for segmentation
            %Note the '1' entry implies that there is a single section
            %for this channel - if not, use an identifier
            %(RunMethod.parameters.namestring) that identifies the
            %section you want do use for segmentation, not just the
            %channel)            
            obj.addImageFileList('main',obj.Moviedir,[obj.RunMethod.parameters.filenamecontains],1);%adds the main image set to the obj.ImageFileList structure with the label main
            obj.TimePoints = size(obj.ImageFileList(1).file_details,2);%Number of timepoints
            obj.EndFrame=obj.TimePoints;
            obj.StartFrame=1;
                %call segmentation function
                tic
                
                history=obj.RunMethod.run(obj);%run the timelapse segmentation method
                showMessage(strcat('Segmentation took',num2str(toc),'seconds'));
                %track segmented cells
                tic
                history=obj.RunTrackMethod.run(obj);%run the run method for that trackyeast object to track the cells
                showMessage(strcat('Tracking took',num2str(toc),'seconds'));
                obj=obj.RunExtractMethod.run(obj);                
            end
        end        
    end
end


