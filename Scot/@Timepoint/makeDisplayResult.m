function obj=makeDisplayResult(obj)
    %MAKE A 2D DISPLAYABLE RESULT FROM THE 3D ENTRY FOR THIS
    %TIMEPOINT
    all=false(obj.Timelapse.ImageSize(2), obj.Timelapse.ImageSize(1),size(obj.Timelapse.Result(obj.Frame).timepoints,2));
      for n=1:size(obj.Timelapse.Result(obj.Frame).timepoints,2)
          all(:,:,n)=obj.Timelapse.Result(obj.Frame).timepoints(n).slices;
      end
          obj.DisplayResult=sum(all,3);
    end
    %This can be made more sophisticated - to deal with display of
    %overlapping cells.
