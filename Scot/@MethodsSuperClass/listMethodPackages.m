function packageList=listMethodPackages()

    % listMethodPackages --- generates a list of the available packages containing Scot method classes
    %
    % Synopsis:  packageList = listMethodPackages
    %
    % Input:     
    %
    % Output:    packageList = cell array of strings, the names of all 
    %            packages containing Scot method classes

    % Notes:     
    
    path=mfilename('fullpath');%path of this file
    r = regexp(path,filesep);
    D = dir(path(1:r(end-1)));%All files and folders in the main Scot folder
    names={D.name};
    packages=strncmp(names,'+',1);
    packages=names(packages);%packages is now a cell array of strings containing the package names.
    packageList=packages;
    %Check if each package really contains any valid method classes
    
    for n=1:length(packages)
        pName=packages{n};
        classes=MethodsSuperClass.listMethodClasses(pName(2:end));
        if isempty(classes)
            ind=strcmp(pName,packageList);
            packageList(ind)=[];
        end
    end
    
    
    