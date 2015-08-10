classdef LevelObject2<LevelObject
   properties
        %Of all object types
        Type%string, 'Preallocated','Timepoint', 'Region', or 'OneCell'
        %Timelapse (defined in superclass)
        %RunMethod (defined in superclass)
        %ObjectNumber (defined in superclass)
        %SegMethod (defined in superclass)mo
        
        %Timepoint objects
        Frame%Integer
        
        %Region objects
        Timepoint%Integer, objectnumber
        TopLeftx
        TopLefty
        xLength
        yLength
        
        %OneCell objects
        Region%Integer, objectnumber     
        CatchmentBasin
        TopLeftThisCellx
        TopLeftThisCelly
        xThisCellLength
        yThisCellLength
        TrackingNumber
   end
   methods
   function obj = LevelObject2
        % LevelObject2 --- constructor used for preallocation of timelapse.LevelObjects array
        %
        % Synopsis:  obj = LevelObject2
        %
        % Input:     
        %
        % Output:    obj = object of class LevelObject2
       
        %Notes:  Run during preallocation of memory for timelapse
        %        segmentation. Creates a dummy level object with fields to
        %        be saved in the timelapse.LevelObjects structure. Then can
        %        be replaced with the correct field values when objects are
        %        created using the copyProperties method.
        obj.Type='Preallocated';
        obj.ObjectNumber=1;
        obj.Timelapse=1;
        obj.Region=1;
        obj.Timepoint=1;
        obj.Frame=1;
        obj.RunMethod=1;
        obj.TopLeftx=1;
        obj.TopLefty=1;
        obj.xLength=1;
        obj.yLength=1;
        obj.CatchmentBasin=1;
        obj.TopLeftThisCellx=1;
        obj.TopLeftThisCelly=1;
        obj.xThisCellLength=1;
        obj.yThisCellLength=1;
        obj.TrackingNumber=1;
   end
   function obj=copyProperties (obj, inputObj)
        % copyProperties --- copies properties of an input level object to an object of class LevelObject2
        %
        % Synopsis:  obj=copyProperties (obj, inputObj)
        %
        % Input:     obj = object of class LevelObject2
        %            inputObj = object of a level class (Timepoint, Region or OneCell)
        %
        % Output:    obj = object of class LevelObject2
       
        %Notes:  Function to be run after creating a new level object during
        %        segmentation - copies the properties of the input level
        %        object to the stored, preallocated version in
        %        timelapse.LevelObjects. Returns an object for saving in the
        %        Timelapse.LevelObjects array.
       
       data=metaclass(inputObj);
       classname=data.Name;
       %Define properties shared by all class types
       
       obj.RunMethod=inputObj.RunMethod.ObjectNumber;%Only the number is saved, not the object, to save memory and allow preallocation
       obj.SegMethod=inputObj.SegMethod.ObjectNumber;%Only the number is saved, not the object, to save memory and allow preallocation
       obj.ObjectNumber=inputObj.ObjectNumber;
       %Define specific properties of each class
       if isa (inputObj, 'Timelapse')
           obj.Type='Timelapse';
           obj.Timelapse=inputObj.ObjectNumber;
       end
       if isa (inputObj, 'Timepoint')
           obj.Type='Timepoint';
           obj.Frame=inputObj.Frame;
           obj.Timelapse=inputObj.Timelapse.ObjectNumber;
       end
       if isa (inputObj, 'Region')
           obj.Type='Region';
           obj.Timepoint=inputObj.Timepoint.ObjectNumber;
           obj.TopLeftx=inputObj.TopLeftx;
           obj.TopLefty=inputObj.TopLefty;
           obj.xLength=inputObj.xLength;
           obj.yLength=inputObj.yLength;
           obj.Timelapse=inputObj.Timelapse.ObjectNumber;
       end
       if isa (inputObj, 'OneCell')
           obj.Type='OneCell';
           obj.Region=inputObj.Region.ObjectNumber;
           obj.CatchmentBasin=inputObj.CatchmentBasin;
           obj.TopLeftThisCellx=inputObj.TopLeftThisCellx;
           obj.TopLeftThisCelly=inputObj.TopLeftThisCelly;
           obj.xThisCellLength=inputObj.xThisCellLength;
           obj.yThisCellLength=inputObj.yThisCellLength;
           obj.TrackingNumber=inputObj.TrackingNumber;
           obj.Timelapse=inputObj.Timelapse.ObjectNumber;
       end
   end       
   end
end