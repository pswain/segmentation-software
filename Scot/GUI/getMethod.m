function method = getMethod(handles, level)
    %Objects used in segmentation are stored in the
    %timelapseObj.TrackingData.cells.methodobj structure. Define the current
    %method object.
    if nargin==1
        level=handles.Level;
    end
    method=handles.methodObjects(handles.Level).objects;
    %check if the object at the current point in the history is a level
    %object - if so, want to set the current method to its runmethod
    
    %Check if the class is a subclass of MethodsSuperClass - if not, it's
    %a level class and the currentMethod should be set to the run method of 
    %this class
    if ~isa(method, 'MethodsSuperClass')
        method=method.RunMethod;      
    end
    method.Info=metaclass(method);
    %Record initial parameter values for the restoreInitial callback
    handles.initialParameters=method.parameters;
end