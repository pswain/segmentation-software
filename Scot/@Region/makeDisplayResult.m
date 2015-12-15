function obj=makeDisplayResult(obj)
        %MAKE A 2D DISPLAYABLE RESULT FROM THE 3D ENTRY FOR THIS
        %TIMEPOINT IN TIMELAPSEOBJ
        obj.DisplayResult=sum(obj.Result,3);
        %This can be made more sophisticated - to deal with display of
        %overlapping cells.
        end