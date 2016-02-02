function extractCellData(cTimelapse)
% extractCellData(cTimelapse)
%
% wrapper function that performs the extraction according to
% cTimelapse.extractionParameters. 
% Simply applies the function:
%   cTimelapse.extractionParameters.extractFunction
% which will usually make use of the parameters:
%   cTimelapse.extractionParameters.functionParameters
%
% sets the extractionParameters to be a field in the extractedData.

disp('Using Parfor extraction - changeback in cTimelapse.extractCellData()')
cTimelapse.extractionParameters.extractFunction=@extractCellDataStandardParfor;
cTimelapse.extractionParameters.extractFunction(cTimelapse)
% cTimelapse.extractCellDataStandardParfor;

[cTimelapse.extractedData(:).extractionParameters] = deal(cTimelapse.extractionParameters);

end

