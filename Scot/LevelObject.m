classdef LevelObject<handle
    properties
    RunMethod%Object of the class that is used to run the segmentation method for this level
    ObjectNumber%Integer, the unique identifier of each level object created during a timelapse segmentation
    Info%To store information about this class coming from the metaclass command. Required by the GUI
    RequiredImages%Structure holding intermediate images required by segmentation methods. These will be available for display by the segmentation editing gui.
    RequiredFields%Structure holding any other data required by segmentation methods - eg structuring elements
    Timelapse%The timelapse object of which this object is a part.
    Result%Logical 4d or 3d matrix, result of segmentation, one 2d image for each cell, 3rd dimension index is the tracking number. 4th is the timepoint (only for timelapse objects)
    DisplayResult%2d or 3d logical matrix, 2-dimensional (flattened) result image for display by the GUI. 3rd dimension is the timepoint (only for timelapse objects)
    Target%2d matrix, the image to be segmented. Not used by timelapse objects
    SegMethod%The method class used to segment this object.
    end
    methods
                  
        function duplicate = copy(this)
            % copy --- returns a deep copy of an input level object (only copies public properties)
            %
            % Synopsis:  duplicate = copy (this)
            %                        
            % Input:     this = an object of a level class
            %
            % Output:    duplicate = a copy of this

            % Notes:     Copying a handle object normally only copies the
            %            handle, so that any changes to the copy affect all
            %            other copies. It's not simple to make true copies
            %            of handle objects but this seems to be the
            %            simplest way that works fast. If we make
            %            properties private at some point in the future
            %            then this code will become more complicated.
            %            This method is adapted from Doug Swartz - see
            %            http://www.mathworks.com/matlabcentral/newsreader/view_thread/257925
            
            this.Info=metaclass(this);           
            constructor=str2func(this.Info.Name);
            duplicate = constructor('Blank');%make a blank copy of the input object
            % Copy all non-hidden properties.
            p = properties(this);
            l = properties(duplicate);
            for i = 1:length(p)
                a=strfind(l,p{i});
                if any(~cellfun('isempty',a))
                    duplicate.(p{i}) = this.(p{i});
                end
            end
        end
        
        function obj=initializeFields(obj)
            % initializeFields --- superclass method to avoid error when initializeFields is run on any level obects
            %
            % Synopsis:  obj = initializeFields (obj)
            %                        
            % Input:     obj = an object of a level class
            %
            % Output:    obj = an object of a level class

            % Notes:     This function does nothing. Is only there to avoid
            %            an error. Subclasses should define their own
            %            initializeFields methods if required.
        end

  
        
        
    end
end