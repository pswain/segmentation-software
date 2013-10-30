function object =  getobj(Timelapse,objecttype,objectname,varargin)
% getobj  ---  retrieves a copy of the object objecttype.objectname from the
%              timelapse ObjectStruct property or creates it if it is not
%              already there.

% Synopsis:    object =  getobj(Timelapse,objecttype,objectname)
%              object =  getobj(Timelapse,objecttype,objectname,varargin)
%
% Input:       Timelapse = an object of a Timelapse class
%              objecttype = package in which the object is stored
%              objectname = class of the object
%              varargin = parameter specification in the standard matlab format.

%
% Output:      object = an object of a objectype.objectname class
%              copied from (or created and added to) the
%              Timelapse.ObjectStructure property.

%Note: This function is the standard function that should be used to obtain
%any object which has the option of being user defined at any point in the
%timelapse. If varargin is not supplied then the parameters are taken from
%Timelapse.SpecifiedParameters. If varargin is supplied then these
%parameters are used in object initiation. If there is a pre-existing
%object of the same class but with different parameters then both are
%stored in Timelapse.ObjectStruct. The exception to this is objects of the
%runmethods package - there can only be one method of each type in the
%runmethods package.


if isempty(Timelapse.ObjectStruct)
    
    path=mfilename('fullpath');%path of this file
    r = regexp(path,'/');%location of characters following '/'characters
    D = dir(path(1:r(end-1))); %all files in the directory above @Timelapse
    D = {D(regexpcmp({D.name},'+.*') & [D.isdir]).name};%cell array of all pakages
    D = regexprep(D,'+','');%take the plus off the package name
    c = cell(size(D));%construction of cell array to construct Timelapse.ObjectStruct with fields of empty structures
    c(:) = deal({struct});

Timelapse.ObjectStruct = cell2struct(c,D,2);
end


if ~ismember(objecttype,fields(Timelapse.ObjectStruct))%No package of the input name exists
    fprintf(['objecttype given is ' objecttype '. Object type must be one of '])
    disp(fields(Timelapse.ObjectStruct))
    error('improper object type')
elseif  ~ismember(objectname,fields(Timelapse.ObjectStruct.(objecttype)))%there is no object of this class yet in the timelapse.ObjectStruct structure
    classString=[objecttype '.' objectname];%create name of the class
    constrFunc=str2func(classString);%create a function handle to the class constructor
    %Create the object using this constructor
    if (nargin>3)
        Timelapse.ObjectStruct.(objecttype)(1).(objectname) = constrFunc(varargin{:});
    else
        Timelapse.ObjectStruct.(objecttype)(1).(objectname) = constrFunc();
    end
    Timelapse.ObjectStruct.(objecttype)(1).(objectname).ObjectNumber=Timelapse.NumObjects;
    Timelapse.NumObjects=Timelapse.NumObjects+1;
    %The object will have been instantiated with default parameters. If no 
    %parameters were input then reset these based on the defaults defined
    %in Timelapse.SpecifiedParameters
    if ~(nargin>3)
        Timelapse.ObjectStruct.(objecttype)(1).(objectname)=Timelapse.ObjectStruct.(objecttype)(1).(objectname).parseparams(Timelapse);
    end
    %Copy to object variable to return
    object =  Timelapse.ObjectStruct.(objecttype)(1).(objectname);
else %There is already at least one object of the input type in Timelapse.ObjectStruct. Compare their parameters
    
    if (nargin>3)%record input parameters for comparison with saved objects
       params=varargin;
    else%No parameters were input, check any that might be stored in timelapse.SpecifiedParameters
        if isfield(Timelapse.SpecifiedParameters.(objecttype),objectname);
            %Could be that there are some parameters specified and others
            %not. Create object to get all of the parameters defined
            classString=[objecttype '.' objectname];%create name of the class
            constrFunc=str2func(classString);%create a function handle to the class constructor
            object = constrFunc();
            params = Timelapse.SpecifiedParameters.(objecttype).(objectname);
            object =  object.changeparams(params{:});           
            inputparameters=object.parameters;
        else%No parameters have been either input to this function or stored in specified parameters.
           %Return an object with the parameters of the last object of
           %this type stored in Timelapse.ObjectStruct
           numObjects=size(Timelapse.ObjectStruct.(objecttype),2);
           for n=1:numObjects
              object=Timelapse.ObjectStruct.(objecttype)(numObjects-n+1).(objectname);
              if ~isempty(object)
                  break
              end
           end
           return
        end            
    end
    %loop through the objects of the input type, testing if their
    %parameters are the same or different from the input parameters
    same=0;
    
    for o=1:size(Timelapse.ObjectStruct.(objecttype),2)
        %If necessary turn the input parameters into a structure to allow comparison
        %with the .parameters field of the saved object(s)
        if ~exist('inputparameters','var')
            inputparameters=struct;
            changefields = params(1:2:length(params));%names of input fields
            changevalues = params(2:2:length(params));%values of input fields
            for i=1:length(changefields)
                inputparameters.(changefields{i}) = changevalues{i};
            end
        end
        if isequal(inputparameters, Timelapse.ObjectStruct.(objecttype)(o).(objectname).parameters)
           same=o;
        end
    end
    if same==0;%There are no saved objects with the input parameters
       %Construct new object
       classString=[objecttype '.' objectname];%create name of the class
       constrFunc=str2func(classString);%create a function handle to the class constructor
       %Create the object using this constructor
       object = constrFunc(params{:});
       object.ObjectNumber=Timelapse.NumObjects;
       Timelapse.NumObjects=Timelapse.NumObjects+1;
       %Now add to the object structure. If the object belongs to the
       %runmethods package it must replace the existing object
       if strcmp(objecttype,'runmethods')
           Timelapse.ObjectStruct.(objecttype).(objectname)=object;
       else
           if isfield(Timelapse.ObjectStruct.(objecttype),objectname);
                nObjects=size([Timelapse.ObjectStruct.(objecttype).(objectname)],2);%number of objects of the input class
           else
               nObjects=0;
           end
           Timelapse.ObjectStruct.(objecttype)(nObjects+1).(objectname)=object;
       end
    else%There is a saved object with the input parameters - return this 
        object=Timelapse.ObjectStruct.(objecttype)(same).(objectname);
    end
     
end
end