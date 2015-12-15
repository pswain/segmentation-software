function [state trainingStates]=classifyBirths(cTimelapse,hmmCell)
% classifies the birth state of all traps in a timelapse by calling the
% single trap function

for trap=1:max(cTimelapse.extractedData(1).trapNum)
    [state{trap} trainingStates{trap}]=cTimelapse.classifyBirthSingleTrap(hmmCell,trap);
end
