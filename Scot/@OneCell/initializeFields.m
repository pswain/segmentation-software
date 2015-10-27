function obj = initializeFields (obj)
    % initializeFields --- generates target and result images for a OneCell object from data stored at the timelapse level
    %
    % Synopsis:  obj = makeResult (obj)
    %
    % Input:     obj = an object of a OneCell class
    %
    % Output:    obj = an object of a OneCell class

    % Notes: This method retrieves result data from the timelapse.Result
    %        property and writes it to the OneCell.Result property. Used
    %        when recreating a cell object from a previously-segmented
    %        dataset.

    %To make obj.Result - copy the entry for this cell from the
    %timelapse object
    if ~isempty(obj.Timelapse.Result)
        if size(obj.Timelapse.Result,4)>=obj.Timelapse.CurrentFrame
            %This cell has been segmented
            if isempty(obj.FullSizeResult)
                obj.FullSizeResult=obj.Timelapse.Result(:,:,obj.trackingnumber, obj.Timelapse.CurrentFrame);
            end
            if isempty (obj.Result)
                region=obj.Timelapse.TrackingData(obj.Timelapse.CurrentFrame).cells(obj.trackingnumber).region;
                obj.Result=obj.Timelapse.Result(region(2): region(2)+region(4)-1,region(1):region(1)+region(3)-1,obj.trackingnumber, obj.Timelapse.CurrentFrame);
            end
            if isempty(obj.Target)
                %Get the target image
                if ~isempty(obj.Region)
                    obj.Region.initializeFields;
                    obj.Target=obj.Region.Target;
                else
                    %There is no defined region object
                    filename=[obj.Timelapse.ImageFileList(obj.Timelapse.Main).directory '/' obj.Timelapse.ImageFileList(obj.Timelapse.Main).file_details(obj.Timelapse.CurrentFrame).timepoints.name];
                    fullSizeTarget=imread(filename);
                    obj.Target=fullSizeTarget(region(2): region(2)+region(4)-1,region(1):region(1)+region(3)-1,obj.trackingnumber, obj.Timelapse.CurrentFrame);
                end
            end
        end
    end

end