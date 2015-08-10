function [handles]=packageMenu_callback(source, eventdata, handles)
handles=guidata(handles.gui);
showMessage(handles,'');
%Need to populate the method menu by calling populateMethod - first need a
%method object that belongs to the package
path=mfilename('fullpath');
k=strfind(path,'/');%COULD BE BACKSLASH ON OTHER PLATFORMS - CHECK THIS
folder=path(1:k(end-1));
packageNames=get(source,'String');
packageName=packageNames(get(source,'Value'));
contents=what([folder '+' packageName{:}]);
fail=true;
while fail==true
   for n=1:size(contents.m,1)
       if fail==false
           break;
       end
        filename=contents.m(n);
        filename=filename{:};
        k=strfind(filename,'.');
        filename=filename(1:k(1)-1);
        constructor=str2func([packageName{:} '.' filename]);
        try
            methodObj=constructor();
            methodObj.Info=metaclass(methodObj);            
        catch
        end
        if exist('methodObj')
            %confirm that this is a method class
                if isa (methodObj, 'MethodsSuperClass')
                %The object exists and is a subclass of MethodsSuperClass - but
                %it still might belong to a superclass of a method class, not
                %the method class itself.
                %See if there are any subclasses in the package
                nClasses=size(methodObj.Info.ContainingPackage.Classes,1);%The number of classes in the package.
                isSuper=false;%not yet shown that the methodObj class is a superclass
                    for c=1:nClasses%Loop through the classes to check - is class number c a superclass of the class that methodObj belongs to?
                        cClass=methodObj.Info.ContainingPackage.Classes(c);
                        cClass=cClass{:};   
                        sClasses=cClass.SuperClasses;
                        for s=1:size(sClasses,1);%loop through the superclasses of class c
                            sClass=sClasses(s);
                            sClass=sClass{:};
                            if strcmp(sClass.Name,methodObj.Info.Name)
                                %the methodObj class is a superclass -
                                %therefore not a method class
                                isSuper=true;
                            end
                        end                     
                    end
                if ~isSuper
                    %have shown that methodObj exists (ie it's m file is a
                    %class), doesn't belong to a superclass of any of the other
                    %classes in the package and  is a subclass of
                    %MethodsSuperClass. So it is a method object                
                fail=false;
                end            
            end
        end
   end
   if ~exist('methodObj')%There were no method class files in the package
        return
   end

handles.currentMethod=methodObj;
handles=populateMethod(handles);

end
guidata(source, handles);
end