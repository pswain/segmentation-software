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


cTimelapse.extractionParameters.extractFunction(cTimelapse)
   
[cTimelapse.extractedData(:).extractionParameters] = deal(cTimelapse.extractionParameters);

end

