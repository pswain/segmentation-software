function obj=initializeFields(obj)
    % initializeFields--- generates target and result images for a Timepoint object from data stored at the timelapse level
    %
    % Synopsis:  obj = initializeFields (obj)
    %
    % Input:     obj = an object of a Timepoint class
    %
    % Output:    obj = an object of a Timepoint class

    % Notes: This method retrieves result data from the timelapse.Result
    %        property and writes it to the Timepoint.Result property. Used
    %        when recreating a Timepoint object from a previously-segmented
    %        dataset.    
    if isempty(obj.Target)
        filename=[obj.Timelapse.ImageFileList(obj.Timelapse.Main).directory '/' obj.Timelapse.ImageFileList(obj.Timelapse.Main).file_details(obj.Frame).timepoints.name];
        obj.Target=imread(filename);
    end
    
    if ~isempty (obj.Timelapse.Result)
        if size(obj.Timelapse.Result,4)>=obj.Timelapse.CurrentFrame
            %There is an entry for this timepoint in the results array
            %(could still be empty)
            obj.Result=obj.Timelapse.Result(obj.Frame).timepoints;
        end
    end
end

