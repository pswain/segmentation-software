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

for posi = positionsToSet
    cTimelapse = cExperiment.loadCurrentTimelapse(posi);
    cTimelapse.extractionParameters = extractParameters;
    cExperiment.cTimelapse = cTimelapse;
    if posi==length(positionsToSet)
        cExperiment.saveTimelapseExperiment(posi);
    else
        cExperiment.saveTimelapse(posi);
    end
end

end

