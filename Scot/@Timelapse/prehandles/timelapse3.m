classdef timelapse3<timelapse
   properties
      Interval%time interval in min
      TimePoints%number of timepoints
      Channels%cell array - eg {'DIC';'GFP';'mCherry'}
      MeasuredChannels%channels to be measured. Vector of indices to the channels array - eg [2 3]
      Moviedir%path of directory where data is stored
      TrackingData%structure carrying the information as to how the segmentation has been done for each cell
      Bin3d%binary image that defines regions in the image that are processed independently. Created by a thresholding method in the timepoint3 class
      Segmented%3d image (x,y,t) showing positions of each detected cell following segmentation.
      Tracked%3d image (x,y,t) showing positions and assigned cell numbers (after tracking) of each cell
      Data%matrix carrying results calculated from tracked and segmented images (cellnumber,timepoint,channel)
      Lengths%vector carrying the number of timepoints at which each cell has been segmented.
      Defaults%used only during segmentation and tracking  - default parameters
      Sections%vector indicating z sections of image stacks used in measuring the data eg [4 5 6]
      Datalength%minimum length of data that will be plotted (ie minumum number of consecutive timepoints at which a cell has been detected)
      ImageSize%2 element vector (x,y) giving the dimensions of the images in the data set eg [512 512]
   end
    
   
   
   methods
             
        function obj=timelapse3(moviedir,interval,sections,channels,measuredchannels,defaults)     
           % timelapse3 --- constructor for timelapse object, segments,tracks and measures timelapse data.
           %
           % Synopsis:  timelapse=timelapse3(moviedir,interval,sections,channels)
           %            timelapse=timelapse3(moviedir,interval,sections,channels,measuredchannels)
           %            timelapse=timelapse3(moviedir,interval,sections,channels,measuredchannels,defaults)
           %
           % Input:     moviedir = string, path to folder in which images are stored
           %            interval = scalar, time interval between images in minutes
           %            sections = vector, z sections to be measured, eg [4 5 6]. Should be an empty matrix ([]) if only a single section was acquired           
           %            channels = cell array, names of the channels, eg {'DIC';'GFP';'mCherry'}
           %            measuredchannels = vector, channels to be measured, indices to the channels array - eg [2 3]
           %            defaults = structure, default segmentation and tracking parameters
           %
           % Output:    timelapse object
           
           % Notes:     This constructor performs segmentation, tracking
           %            and measurement of mean fluorescence for the input channels.
                      
           %Copy input properties
           if ischar(moviedir)==1
               obj.Moviedir=moviedir;
           else 
                obj.Moviedir=moviedir{:};
           end
           obj.Interval=interval;           
           obj.Sections=sections;%Sections should be an empty array for a single section acquisition            
           obj.Channels=channels;
           if nargin>4
               obj.MeasuredChannels=measuredchannels;
           else%do not measure fluorescence if no measuredchannels input
               obj.MeasuredChannels=0;
           end
           if nargin>5
               obj.Defaults=defaults;
           else%supply default parameters if no defaults structure has been input
               obj.Defaults.method='edges+contours';
               obj.Defaults.order=[1 2 3 4 5 6 7];
               obj.Defaults.erodetarget=0.5;
               obj.Defaults.disksize=2;
               obj.Defaults.threshmethod=1;
               obj.Defaults.depth=1;
               obj.Defaults.maxdrift=40;
               %active contour defaults
               obj.Defaults.contours.method='chan';
               obj.Defaults.contours.used=1;
               obj.Defaults.contours.mu=0.2;
               obj.Defaults.contours.iterations=100;
               obj.Defaults.contours.fit='none';
           end
           %define default properties
           obj.Datalength=10;
           obj.ImageSize=[512 512];%THIS NEEDS TO BE MADE GENERIC - WRITE A METHOD TO OPEN THE FIRST IMAGE TO GET THIS INFORMATION
           %call segmentation function
           tic            
           obj=obj.segmenttimelapse;
           disp(strcat('Segmentation took',num2str(toc),'seconds'));
           %track segmented cells
           tic
           obj=obj.trackyeast;
           disp(strcat('Tracking took',num2str(toc),'seconds'));
           if obj.MeasuredChannels~=0%ie if a fluorescence channel number has been supplied
               tic
               obj=obj.measurefluorescence;
               disp(strcat('Data measurement took',num2str(toc),'seconds'));
               obj=obj.datalength;
            end
        end
   end
end
    
    
