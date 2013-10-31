function obj = makeResult (obj)
    % makeResult --- generates the .Result stack from images stored at the timelapse level
    %
    % Synopsis:  obj = makeResult (obj)
    %
    % Input:     obj = an object of a region class
    %
    % Output:    obj = an object of a region class

    % Notes: Where a timelapse segmentation method creates results by
    %        creating objects at lower levels (cell objects) then
    %        the results will not be stored at the region level but in
    %        the timelapse.Result field. This method retrieves this data
    %        and writes it to the region.Result property.

    %To make obj.Result - copy the entry for this timepoint from the
    %timelapse object
    if ~isempty(obj.Timelapse.Result)
        if size(obj.Timelapse.Result,4)>=obj.Timepoint.Frame
            obj.Result=obj.Timelapse.Result(obj.TopLefty: obj.TopLefty+obj.yLength-1, obj.TopLeftx:obj.TopLeftx+obj.xLength-1,:, obj.Timelapse.CurrentFrame);
        end
    end

end