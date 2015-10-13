function selectCellsToPlotAutomatic(cExperiment,positionsToCheck,params)
if nargin<2
    positionsToCheck=find(cExperiment.posTracked);
    %     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3 || isempty(params)
    cTimelapse=cExperiment.returnTimelapse(1);
    %load([cExperiment.saveFolder '/' cExperiment.dirs{1},'cTimelapse']);
    
    params.fraction=.8; %fraction of timelapse length that cells must be present or
    params.duration=3;%length(cTimelapse.cTimepoint); %number of frames cells must be present
    params.framesToCheck=length(cTimelapse.cTimepoint);
    params.framesToCheckEnd=1;
    
    if ~isempty(cExperiment.timepointsToProcess)
        loc=find(cExperiment.timepointsToProcess);
        params.duration=loc(end); %number of frames cells must be present
        params.framesToCheck=max(cExperiment.timepointsToProcess);
        params.framesToCheckEnd=min(cExperiment.timepointsToProcess);
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
end

if size(cExperiment.cellsToPlot,3)>1
    cExperiment.cellsToPlot=cell(1);
    for i=1:length(cExperiment.posTracked)
        cExperiment.cellsToPlot{i}=sparse(zeros(1,1));
    end
end

%% Run the tracking on the timelapse
for i=1:length(positionsToCheck)
    experimentPos=positionsToCheck(i);
    cTimelapse=cExperiment.returnTimelapse(experimentPos);
    %load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse.automaticSelectCells(params);
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.cellsToPlot{i}=cTimelapse.cellsToPlot;
    cExperiment.saveTimelapseExperiment(experimentPos);
end