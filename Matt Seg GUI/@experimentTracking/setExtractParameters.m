function setExtractParameters( cExperiment,positionsToSet,extractParameters)
% setExtractParameters( cExperiment,positionsToExtract,extractParameters)
%
% set the extractParameters to the be the extraction parameters for each of
% the timelapses in positionsToExtract.
%
% cExperiment           :   object of the experimentTracking class
% positionsToExtract    :   array of indices of positions for which to set
%                           the extractParameters. defaults to all the
%                           positions.
% extractParameters     :   a parameter structure that determines which
%                           function should be used for the extraction and
%                           its parameters. Structure with the fields:
%                               extractFunction   : function handle for function usedin extraction
%                               extractParameters : structure of parameters taken by that function
%                           defaults to the default parameters stored as a
%                           constant property of timelapseTraps.
%
% running the method with no inputs returns all extractionParameters to
% default.

if nargin<2 || isempty(positionsToSet)
    positionsToSet=1:length(cExperiment.dirs);
end

if nargin<3
    
    extractParameters = timelapseTraps.defaultExtractParameters;
    
end

% Start logging protocol
cExperiment.logger.add_arg('extractionParameters',extractParameters);
cExperiment.logger.start_protocol('setting extraction parameters',length(positionsToSet));
try

for posi = positionsToSet
    cTimelapse = cExperiment.loadCurrentTimelapse(posi);
    cTimelapse.extractionParameters = extractParameters;
    cExperiment.cTimelapse = cTimelapse;
    cExperiment.saveTimelapseExperiment(posi)    
end

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end

