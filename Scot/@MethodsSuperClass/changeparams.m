function TM = changeparams(TM,varargin)
% changeparams --- change current parameters to some new value. Follows matlab convention.

% Synopsis:        TM = changeparams(TM,varargin)
%
% Input:           TM = object of the TrackMethods class.
%                  varargin = specification of parameters according the the
%                             usual matlab convention.
%
% Output:          TM = an object of a TrackMethods class

changefields = varargin(1:2:length(varargin));%names of fields to be changed
changevalues = varargin(2:2:length(varargin));%values they are to take
%try
%    any(~ismember(changefields,fields(TM.parameters)))
%catch
%    disp('stop');
%end

if any(~ismember(changefields,fields(TM.parameters)))
    fprintf('variables given: \n')
    disp(varargin)
    fprintf('parameters of this class:\n')
    disp(fields(TM.parameters))
    error('parameters given are not parameters of this class')
elseif length(changefields)~=length(unique(changefields))
    fprintf('variables given: \n')
    disp(varargin)
    error('each parameter should be specified only once')
else
    for i=1:length(changefields)
        TM.parameters.(changefields{i}) = changevalues{i};
    end
end
    


end