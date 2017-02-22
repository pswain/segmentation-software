function searchString = addSecondaryChannel(cExperiment,searchString)
%searchString = addSecondaryChannel(cExperiment,searchString)
%
% add channel to every timelapse in the cExperiment object. searchString
% is a string or cellstr of all channels to add that is passed to the 
% equivalent TIMELAPSETRAPS method.
%
% See also, TIMELAPSETRAPS.ADDSECONDARYTIMELAPSECHANNEL

if nargin<2 || isempty(searchString)
    searchString = inputdlg('Enter the string to search for the secondary (fluorescent) channel images'...
                            ,'SearchString',1,cExperiment.channelNames(end));
    searchString = searchString{1};
end

if ischar(searchString)
    searchString = cellstr(searchString);
end

assert(iscellstr(searchString),...
    'Specify channels to add either as a single string, or a cell array of strings');

% Start logging protocol
cExperiment.logger.start_protocol(...
    sprintf('adding channel(s) %s',strjoin(searchString,', ')),...
    length(cExperiment.dirs));

try

for i=1:length(cExperiment.dirs)
    cExperiment.loadCurrentTimelapse(i);
    cExperiment.cTimelapse.addSecondaryTimelapseChannel(searchString);
    cExperiment.saveTimelapseExperiment;
end

cExperiment.channelNames = [cExperiment.channelNames,searchString];

cExperiment.saveExperiment;

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end


end
