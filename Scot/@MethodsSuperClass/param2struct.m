function ParamCell = param2struct(TM)
% param2struct --- converts the parameters property of a method class
%                  object to a cell format.

% Synopsis:        TM = param2struct(TM)
%
% Input:           TM = object of the TrackMethods class.
%                  
%
% Output:          TM = an object of a TrackMethods class

%Notes: converts the parameters property of a TrackMethods subclass from a Parameter structure of the form

% ParamStruct = struct
%     parameter1name: parameter1value
%     parameter2name: parameter2value
%     ....

% To the form used in the timelapse class for defining parameters. i.e.

%    ParamCell = {ClassName,{'parameter1name',parameter1value,'parameter2name',parameter2value}}

%This can then be imposed on any subsequent substantiations of of Timelapse by

%    Timelapse3(....,'TrackMethods',ParamCell)

%Or on calls of the specific class/method/function by:

%    Tm.setparameters(ParamCell{2}{:})

%provided it is written to follow the matlab convention.
%When this is used at the instantiation of timelapse3 is should be noted
%that to give parameters for multiple classes the cells will need to be
%combined as:

%    Timelapse3(....,'TrackMethods',[ParamCell-1 paramCell-2])

fieldnames = fields(TM.parameters);
fieldvalues = struct2cell(TM.parameters);
params = cell(1,2*length(fieldnames));
for i=1:length(fieldnames)
    params(2*i - 1) = fieldnames(i);
    params(2*i) = fieldvalues(i);
    
end

ParamCell = cell(1,2);
ParamCell{1} = class(TM);
ParamCell{2} = params;



end