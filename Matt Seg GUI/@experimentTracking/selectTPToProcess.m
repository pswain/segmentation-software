function selectTPToProcess(cExperiment,positionsToCrop)

load([cExperiment.saveFolder '/' cExperiment.dirs{1},'cTimelapse']);

if ~isempty(cExperiment.timepointsToProcess)
    loc=find(cExperiment.timepointsToProcess);
    params.framesToCheckStart=loc(1);
    params.framesToCheckEnd=loc(end);
else
    params.framesToCheckStart=1;
    params.framesToCheckEnd=length(cTimelapse.cTimepoint);

end

num_lines=1;clear prompt; clear def;
prompt(1) = {'Starting Timepoint'};
prompt(2) = {['Ending Timepoint (max TP ',num2str(length(cTimelapse.cTimepoint)),')']};
dlg_title = 'Tracklet params';
def(1) = {num2str(params.framesToCheckStart)};
def(2) = {num2str(params.framesToCheckEnd)};
answer = inputdlg(prompt,dlg_title,num_lines,def);

startTP=str2double(answer{1});
endTP=str2double(answer{2});

cExperiment.timepointsToProcess=startTP:endTP;

cExperiment.saveExperiment();

