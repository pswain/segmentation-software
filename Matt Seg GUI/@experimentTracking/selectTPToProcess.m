function selectTPToProcess(cExperiment,positionsToCrop,tpToProcess)
% selectTPToProcess(cExperiment,positionsToCrop)
%
% tpToprocess  -  an array of timepoints to process. If empty selected by
%                 GUI. Best if it is continuous (i.e. x:y)
%
% sets the timepointsToProcess field of both cExperiment object and all its
% children cTimelapse objects. also sets their timepointsProcessed field to
% false for timepoints outside the range of timepointsToProcess. This is
% done because subsequent processing steps will only be applied to the
% timepoints listed as timepointsToProcess.

cTimelapse=cExperiment.returnTimelapse(length(cExperiment.dirs));
%Load last one in case it has fewer timepoints as sometimes happens in an interrupted experiment.

if nargin<2
    positionsToCrop=1:length(cExperiment.dirs);
end

if nargin<3 || isempty(tpToProcess);

if ~isempty(cExperiment.timepointsToProcess)
    params.framesToCheckStart=(cExperiment.timepointsToProcess(1));
    params.framesToCheckEnd=cExperiment.timepointsToProcess(end);
else
    params.framesToCheckStart=1;
    params.framesToCheckEnd=length(cTimelapse.cTimepoint);

end

num_lines=1;clear prompt; clear def;
prompt(1) = {'In contrast with cropTP, this keeps the timepoints associated with the timelapse, but just notes that they should not be processed. This is generally prefferable to cropping. Starting Timepoint'};
prompt(2) = {['Ending Timepoint (max TP ',num2str(length(cTimelapse.cTimepoint)),')']};
dlg_title = 'Tp To Process';
def(1) = {num2str(params.framesToCheckStart)};
def(2) = {num2str(params.framesToCheckEnd)};
answer = inputdlg(prompt,dlg_title,num_lines,def);

startTP=str2double(answer{1});
endTP=str2double(answer{2});

cExperiment.timepointsToProcess=startTP:endTP;
else
    cExperiment.timepointsToProcess= tpToProcess;
    startTP = min(tpToProcess);
    endTP = max(tpToProcess);
end
cExperiment.saveExperiment();
waitbar_h = waitbar(0);
for i=1:length(positionsToCrop)
    currentPos=positionsToCrop(i);
    cTimelapse=cExperiment.loadCurrentTimelapse(currentPos);
    cTimelapse.timepointsToProcess = cExperiment.timepointsToProcess;
    % set any elements of the timepointsProcessed field outside the range
    % of timepoints to be processed to false. and ensure its length is
    % endTP.
    cTimelapse.timepointsProcessed(end+1:endTP) = false;
    cTimelapse.timepointsProcessed(endTP+1:end) = [];
    cTimelapse.timepointsProcessed(~ismember(1:length(cTimelapse.timepointsProcessed),cTimelapse.timepointsToProcess)) = false;
    cExperiment.cTimelapse = cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);   
    clear cTimelapse;
    waitbar(i/length(positionsToCrop),waitbar_h,sprintf('timepoints set for position %d of %d ...',i,length(positionsToCrop)));
end
close(waitbar_h)
