function obj=makeDisplayResult(obj)

    % makeDisplayResult --- Creates a structure of 2d images for display from segmented timelapse data
    %
    % Synopsis:  obj = makeDisplayResult (obj)
    %
    % Input:     obj = an object of a Timelapse class
    %
    % Output:    obj = an object of a Timelapse class

    % Notes: 
    
    showMessage('Making result images for display');
    %Initialize
    obj.DisplayResult=struct('timepoints',{});
    a=sparse(false(obj.ImageSize(2), obj.ImageSize(1)));
    obj.DisplayResult(obj.TimePoints).timepoints=a;
    %Loop through the timepoints
    for t=1:size(obj.Result,2)
      obj.DisplayResult(t).timepoints=a;
      for n=1:size(obj.Result(t).timepoints,2)
          if ~isempty(obj.Result(t).timepoints(n).slices)
              obj.DisplayResult(t).timepoints=(obj.DisplayResult(t).timepoints|obj.Result(t).timepoints(n).slices(1:obj.ImageSize(2), 1:obj.ImageSize(1)));
          end
      end
    end
    