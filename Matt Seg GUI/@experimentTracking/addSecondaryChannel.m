function searchString = addSecondaryChannel(cExperiment,searchString)
%searchString = addSecondaryChannel(cExperiment,searchString)
%
% add channel to every timelapse in the cExperiment object. searchString
% is a string.

if nargin<2 || isempty(searchString)
    searchString = inputdlg('Enter the string to search for the secondary (fluorescent) channel images','SearchString',1,{'GFP'});
    searchString = searchString{1};
end

% Start logging protocol
cExperiment.logger.start_protocol(['adding channel ',searchString],length(cExperiment.dirs));

try

for i=1:length(cExperiment.dirs)
    cExperiment.loadCurrentTimelapse(i);
    cExperiment.cTimelapse.addSecondaryTimelapseChannel(searchString);
    cExperiment.saveTimelapseExperiment(i);
end

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

cExperiment.channelNames{end+1}=searchString;


end
