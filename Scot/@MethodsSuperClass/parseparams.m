function TM = parseparams(TM,Timelapse)
% parseparams ---  change current parameters to those specified in the
%                  SpecifiedParameters property of Timelapse.

% Synopsis:        TM = parseparams(TM,Timelapse)
%
% Input:           TM = object of a methods class.
%                  Timelapse = an object of the Timelapse class.
%
% Output:          TM = an object of a TrackMethods class
if isfield(Timelapse.SpecifiedParameters.(regexprep(class(TM),'\..*','')),regexprep(class(TM),'.*\.',''))%use regular expressions to cut off the package name
   TM =  TM.changeparams(Timelapse.SpecifiedParameters.(regexprep(class(TM),'\..*','')).(regexprep(class(TM),'.*\.','')){:});%THIS LINE WILL ERROR WHEN WE CHANGE THE FIELDS OF SPECIFIED PARAMETERS TO PACKAGE NAMES.
end
end