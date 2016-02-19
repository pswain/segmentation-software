function extractCellInformation(cExperiment,positionsToExtract,doParameterGUI,extractParameters)
% extractCellInformation(cExperiment,positionsToExtract,doParameterGUI,extractParameters)
%
% function to extract data for each position.
%
% cExperiment           :   object of the experimentTracking class
% positionsToExtract    :   list of position to extract data from. Also the
%                           list of positions for which the extraction
%                           parameters will be set if they are changed.
%                           Defaults to all positionstracked in the
%                           experiment (so cExperiment.posTracked)
% doParameterGUI        :   boolean of whether to open an editing GUI that allows you
%                           to set various extraction parameters. Defaults to true. 
% extractParameters     :   a parameter structure that will be saved to:
%                                cTimelapse.extractionParameters
%                           for each of the positions in
%                           positionsToExtract. For form of the structure
%                           see timelapseTraps.defaultExtractionParameters
%
% Basically just call cTimelapse.extractCellData for each timepoint.
if nargin<2 || isempty(positionsToExtract)
    positionsToExtract=find(cExperiment.posTracked);
end

if nargin<3 || isempty(doParameterGUI)
    doParameterGUI = true;
end

if doParameterGUI 
    if nargin<4
    cTimelapse = cExperiment.loadCurrentTimelapse(positionsToExtract(1));
    extractParameters = cTimelapse.extractionParameters;
    end
    extractParameters = cExperiment.guiSetExtractParameters(extractParameters);
end

% only set the Extract Parameters if either parameters have been provided
% or the parameter setting GUI was invoked. Was felt best to set it all in
% one go - less time efficient but if it gets stopped the appropriate
% extractionParameters are saved.
if doParameterGUI || nargin>3
    cExperiment.setExtractParameters(positionsToExtract,extractParameters)
end


for i=1:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    cTimelapse=cExperiment.returnTimelapse(experimentPos);
    cTimelapse.extractCellData;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end