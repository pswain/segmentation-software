function obj = loadparameters(obj,varargin)
% loadparameters --- populates the SpecifiedParameters structure of the
%                    Timelapse object.

% Synopsis:          obj = loadparameters(obj,varargin)
%
% Input:             obj = an object of a timelapse class
%                    varargin = parameter definitions. Should be given at
%                    the instatiation of Timelapse and should be a nested
%                    version of the standard matlab form:
%                    obj = Timelapse3(...., 'classtype1',{'class1name',{'param1',value1,'param2',value2},'class2name',{'param1',value1} },'classtype2' ....)
%
%
% Output:            obj = an object of a timelapse class

%Notes: Timelapse.SpecifiedParameters is a structure saving the default
%values of the parameters given at the instatiation of an object of the
%Timelapse class. The parameters are stored as a structure as a cell array
%of the form usually passed as varargin:
%   {'param1name', param1value,'param2name',param2value}
%They are addressed as so that the cell array associated with class 'class'
%of type* 'classtype' is stored in:
%   Timelapse.SpecifiedParameters.classtype.class
%It should not be necessary for developers to access these directly
%provided they use the parseparams methods of the super classes as advised.


% * classtypes were instigated so that naming did not have to be unique
%across the class types. for example, there could be classes labeled
%'segmethod1' for both the timepoint segmentation method and the cell
%segmentation methods. They are labeled according to the packages they are
%stored in.

%DEVELOPER NOTE Might be worth instantiating every object for which there
%are parameter just to make sure parameters work.


if isempty(obj.SpecifiedParameters)
    
    D = MethodsSuperClass.listMethodPackages;
    D = regexprep(D,'+','');%take the plus off the package name
    c = cell(size(D));%construction of cell array to construct Timelapse.SpecifiedParameters with fields of empty structures
    c(:) = deal({struct});
    obj.SpecifiedParameters = cell2struct(c,D,2);
    
end
if ~isempty(varargin)%varargin should be given as .... 'classtype1',{'class1',{'param1',param1value,'param2',value2},'class2',{{'param1',param1value}},'classtype2',....
    classtypes = varargin(1:2:length(varargin)); %pick classtypes out of varargin
    if length(classtypes)~=length(unique(classtypes))
        disp(varargin)
        error('the parameters for each classtype should only be specfied once.')
    elseif any(~ismember(classtypes,fields(obj.SpecifiedParameters)))
        error('erroneous class type. Classtypes should be one of the following: ''runmethods'' ''timelapsesegmethods'', ''timepointsegmethods'',''cellsegmethods'' or '' trackmethods'' ')
    else
        for i=1:length(classtypes)
            classnames = varargin{2*i}(1:2:length(varargin{2*i})); %for each classtype pick the names of all the classes which have parameters specified
            classparameters = varargin{2*i}(2:2:length(varargin{2*i}));%pick out the associated parameters
            if length(classnames)~=length(unique(classnames))
                disp(varargin{2*i})
                error('the parameters for each class should only be specfied once')
                
            else
                for j = 1:length(classparameters)
                    if length(classparameters{j}(1:2:length(classparameters{j}))) ~= length(unique(classparameters{j}(1:2:length(classparameters{j}))));
                        disp(classnames{j})
                        disp(classparameters{j})
                        error('value for each parameter should only be specified once')
                    end
                    
                end
                obj.SpecifiedParameters.(classtypes{i}) = cell2struct(classparameters,classnames,2);
            end
        end
    end
    
end
end