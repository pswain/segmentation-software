function selectTPToProcess(cExperiment,positionsToCrop)

cTimelapse=cExperiment.returnTimelapse(length(cExperiment.dirs));%Load last one in case it has fewer timepoints.
%load([cExperiment.saveFolder '/' cExperiment.dirs{1},'cTimelapse']);

if nargin<2
    positionsToCrop=1:length(cExperiment.dirs);
end

if ~isempty(cExperiment.timepointsToProcess)
    loc=find(cExperiment.timepointsToProcess);
    params.framesToCheckStart=loc(1);
    params.framesToCheckEnd=loc(end);
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

cExperiment.saveExperiment();

for i=1:length(positionsToCrop)
    currentPos=positionsToCrop(i);
%     load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cExperiment.cTimelapse=cExperiment.returnTimelapse(currentPos);
    cExperiment.cTimelapse.timepointsToProcess = cExperiment.timepointsToProcess;
    cExperiment.cTimelapse.timepointsProcessed(~ismember(1:length(cExperiment.cTimelapse.timepointsProcessed),cExperiment.cTimelapse.timepointsToProcess)) = false;
    cExperiment.saveTimelapseExperiment(currentPos);   
    clear cTimelapse;
end

