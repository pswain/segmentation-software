function autoSelect(cExpGUI)

posVals=get(cExpGUI.posList,'Value');
    load([cExpGUI.cExperiment.rootFolder '/' cExpGUI.cExperiment.dirs{1},'cTimelapse']);

params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=length(cTimelapse.cTimepoint); %number of frames cells must be present
params.framesToCheck=length(cTimelapse.cTimepoint);
params.framesToCheckEnd=1;

if ~isempty(cExpGUI.cExperiment.timepointsToProcess)
    loc=find(cExpGUI.cExperiment.timepointsToProcess);
    params.duration=loc(end); %number of frames cells must be present
    params.framesToCheck=loc(end);
    params.framesToCheckEnd=loc(1);
    
end
    

    num_lines=1;clear prompt; clear def;
    prompt(1) = {'Fraction of whole timelapse a cell must be present'};
    prompt(2) = {'OR - number of frames a cell must be present'};
    prompt(3) = {'Cell must appear in the first X frames'};
    prompt(4) = {'Cell must be present after frame X'};

    dlg_title = 'Tracklet params';    
    def(1) = {num2str(params.fraction)};
    def(2) = {num2str(params.duration)};
    def(3) = {num2str(params.framesToCheck)};
    def(4) = {num2str(params.framesToCheckEnd)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    params.fraction=str2double(answer{1});
    params.duration=str2double(answer{2});
    params.framesToCheck=str2double(answer{3});
    params.framesToCheckEnd=str2double(answer{4});




cExpGUI.cExperiment.selectCellsToPlotAutomatic(posVals,params);
