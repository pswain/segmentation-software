%Superclass for timelapse classes. Allows methods to be shared between
%timelapse classes with different inputs.
classdef Timelapse<LevelObject
    properties
        Interval%integer, time interval in min
        TimePoints%integer, number of timepoints
        Moviedir%path of directory where data is stored
        ImageFileList%Structure array of the location of each image file used in the timelapse. Can be edited with (add/rm)ImageFileList and accessed with getimage method
        Data%matrix carrying results calculated from tracked and segmented images (cellnumber,timepoint,channel)
        ImageSize%2 element vector (x,y) giving the dimensions of the images in the data set eg [512 512]
        SpecifiedParameters %This a structure of cell arrays that specifies changes to the defaults for all classes. Any class with alterable parameters should have defaults specified.
        ObjectStruct %Structure for holding instantiated classes in order to store parameters and save instantiating them over and over again. Accessed using the getobj method.
        TrackingData=struct('cells',{});%structure carrying the information as to how the segmentation has been done for each cell
        CurrentFrame%Integer. Used to keep track of which timepoint is currently being segmented
        StartFrame;%Integer. The timepoint at which segmentation should begin
        EndFrame;%Integer. The timepoint after which segmentation should end.
        CurrentCell%Integer. The tracking number of the cell on which segmentation is currently being attempted
        Name%A name for this experiment.
        NumObjects;%The number of level objects (of classes OneCell, Timepoint, or Region) that have been made in the course of segmentation
        RunTrackMethod;%object of class RunTrackMethod. Will get and run a tracking method object
        RunExtractMethod;%object of class RunExtractMethod. Will get and run an extractdata method object
        Main%integer, index to the 'main' entry in the structure ImageFileList - holds the details of the files to be used in segmentation
        HistorySize%integer, index to the last entry in history - keeps track of how many objects have been recorded, and therefore where to put the next one. Necessary because of the preallocation of the history
        LevelObjects%structure, carrying the level objects generated during timelapse segmentation (without images)
        NumLevelObjects%integer, index to the last entry in LevelObjects - kepps track of how many objects have been recorded and therefore where to put the next one. Allows preallocation.
        PostHistory%vector of integers, object numbers of methods applied to the timelapse after segmentation
        Furniture%Structure, showing details of features present at all timepoints that are not cells, eg microfluidic traps. Has two fields: .centres, 2xn matrix - centroids [x y] of all seperate features in the image, and .refimages, 3d matrix with sample images showing the features without cells
    end
    methods (Abstract)

    end
    methods (Static)
        obj=loadTimelapse(fileName);
        metaData=parseMetadata(folder);

    end
end