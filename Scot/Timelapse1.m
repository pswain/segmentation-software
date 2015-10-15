classdef Timelapse1<Timelapse
    properties
    end
  
    methods
        function obj=Timelapse1(varargin)
            % Timelapse1 --- constructor for timelapse object, creates Timelapse object, but does not segment
            %
            % Synopsis:  timelapse=Timelapse1(moviedir, interval, identifier)
            %            timelapse=Timelapse1(moviedir, interval)
            %            timelapse=Timelapse1(moviedir)
            %            timelapse=Timelapse1
            %
            % Input:     moviedir = string, path to folder in which images are stored
            %            interval = double, time in minutes between frames
            %            identifier = string, present in one file per timepoint, to be used as the main segmentation target
            %
            % Output:    obj= object of class timelapse1
            
            % Notes:     This constructor is used to create a Timelapse
            %            object for initiation and parameterization of
            %            segmentation methods, prior to running a
            %            segmentation. To create an object and run
            %            segmentation with default or input methods and
            %            parameters use the alternative class Timelapse3.
            
            %Return an object with no properties initialized if there is a
            %single argument, the string 'Blank'.
            if nargin==1
                if ischar(varargin{1})
                    if strcmp(varargin{1},'Blank')
                        return;
                    end
                end
            end
            %Define input properties - moviedir and interval            
            if nargin<2
                %set default time interval (5 min)
                obj.Interval=5;
            else
                obj.Interval=varargin{2};                
            end
            if nargin==0
                obj.Moviedir=uigetdir('afp://sce-bio-c01949.bio.ed.ac.uk/home0/iclark/Documents','Select directory that contains your images');
            else                                              
                if ischar(varargin{1})
                    obj.Moviedir=varargin{1};
                else
                    obj.Moviedir=uigetdir;
                end
            end        
            
            %Initiate CurrentFrame + CurrentCell properties
            obj.CurrentFrame=1;
            obj.CurrentCell=1;
               
                
            %Initialize object number, NumObjects and NumLevelObjects, PostHistory and historysize fields
            obj.ObjectNumber=1;
            obj.NumObjects=2;
            obj.NumLevelObjects=0;
            obj.PostHistory=struct('objnumbers',{},'packages',{});
            obj.HistorySize=0;
            
            %Initialize (empty) SpecifiedParameters structure
            obj.loadparameters();
            
            
            %create run method objects with default parameters.
            if nargin==3
                obj.RunMethod=obj.getobj('runmethods','RunTLSegMethod', 'filenamecontains',varargin{3});
            else                
                obj.RunMethod=obj.getobj('runmethods','RunTLSegMethod');
            end
            obj.RunTrackMethod=obj.getobj('runmethods','RunTrackMethod');
            obj.RunExtractMethod=obj.getobj('runmethods','RunExtractMethod');
                       
            %Populate the 'main' property of the image file list - these will be used for segmentation
            %Note the '1' entry implies that there is a single section
            %for this channel - if not, use an identifier
            %(RunMethod.parameters.namestring) that identifies the
            %section you want do use for segmentation, not just the
            %channel)            
            [obj index]=obj.addImageFileList('main',obj.Moviedir,[obj.RunMethod.parameters.filenamecontains],1);%adds the main image set to the obj.ImageFileList structure with the label main
            %Load one file to determine the image size
            filename=[obj.ImageFileList(index).directory filesep obj.ImageFileList(index).file_details(1).timepoints.name];
            im=imread(filename);            
            obj.ImageSize=[size(im,2) size(im,1)];
            clear im;

            
            
            obj.TimePoints = size(obj.ImageFileList(1).file_details,2);%Number of timepoints
            obj.EndFrame=obj.TimePoints;
            obj.StartFrame=1;
                       
            %Redefine the default last timepoint to segment
            obj.RunMethod.parameters.end=obj.TimePoints;
            obj.setMethodObjField(obj.RunMethod.ObjectNumber, 'parameters.end', obj.EndFrame);
            
            %Initialize the LevelObjects property
           % obj.LevelObjects=struct('objects',{},'numbers',{});                  
            end
    end        
end


