function obj=makeResult(obj)
    % makeResult --- generates the .Result stack from images stored at the timelapse level
    %
    % Synopsis:  obj = makeResult (obj)
    %
    % Input:     obj = an object of a timepoint class
    %
    % Output:    obj = an object of a timepoint class

    % Notes: Where a timelapse segmentation method creates results by
    %        creating objects at lower levels (cell or region objects) then
    %        the results will not be stored at the timepoint level but in
    %        the timelapse.Result field. This method retrieves this data
    %        and writes it to the timepoint.Result property.

    %To make obj.Result - copy the entry for this timepoint from the
    %timelapse object
    if ~isempty(obj.Timelapse.Result)
        if size(obj.Timelapse.Result,4)>=obj.Frame
            obj.Result=obj.Timelapse.Result(:,:,:,obj.Frame);
        end
    end
end          