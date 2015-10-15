function handles=populatePackage(handles)
    
    %Check if the current method is in the runmethods package. If so, need
    %to disable the package menu.
    if isempty(handles.currentMethod.Info)
        handles.currentMethod.Info=metaclass(handles.currentMethod);
    end
        %create a drop down list of available packages
        thisPath=mfilename('fullpath');
        k=strfind(thisPath,'/');
        thisPath=thisPath(1:k(end-1));
        fileDirectory = fileparts(thisPath);
        dirDetails=what(fileDirectory);
        packageList=dirDetails.packages;
        set(handles.packageMenu,'String',packageList);
    if strcmp(handles.currentMethod.Info.ContainingPackage.Name,'runmethods')
        %set(handles.packageMenu,'Enable','off');
    else
        %set(handles.packageMenu,'Enable','off');
    end
        thisPackageIndex=ind2sub(size(packageList), strmatch(handles.currentMethod.Info.ContainingPackage.Name, packageList, 'exact'));
        set(handles.packageMenu,'Value',thisPackageIndex);
end
