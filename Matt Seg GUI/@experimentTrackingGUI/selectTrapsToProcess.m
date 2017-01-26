function selectTrapsToProcess(cExpGUI)
% selectTrapsToProcess(cExpGUI)
% see function name.
%
% See also, EXPERIMENTTRACKING.IDENTIFYTRAPSTIMELAPSES

posVals=get(cExpGUI.posList,'Value');
cExpGUI.cExperiment.identifyTrapsTimelapses(posVals);
