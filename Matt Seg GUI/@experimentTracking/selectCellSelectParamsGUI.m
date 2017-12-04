function [ params ] = selectCellSelectParamsGUI(cExperiment )
%[ params ] = selectCellSelectParamsGUI(cExperiment )
%
% opens a small GUI to select parameters used for automatically selecting
% cells to extract data for.

    cTimelapse=cExperiment.returnTimelapse(1);
    
    params.fraction=.8; %fraction of timelapse length that cells must be present or
    params.duration=3;%length(cTimelapse.cTimepoint); %number of frames cells must be present
    params.framesToCheck=length(cTimelapse.cTimepoint);
    params.framesToCheckEnd=1;
    params.maximumNumberOfCells = Inf;
    
    
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
    prompt(5) = {'Select a maximum of X cells (useful if you want to check cells and not spend ages)'};

    dlg_title = 'Tracklet params';
    def(1) = {num2str(params.fraction)};
    def(2) = {num2str(params.duration)};
    def(3) = {num2str(params.framesToCheck)};
    def(4) = {num2str(params.framesToCheckEnd)};
    def(5) = {num2str(params.maximumNumberOfCells)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    params.fraction=str2double(answer{1});
    params.duration=str2double(answer{2});
    params.framesToCheck=str2double(answer{3});
    params.framesToCheckEnd=str2double(answer{4});
    params.maximumNumberOfCells = str2double(answer{5});

    % write to appropriate cExperiment field.
    cExperiment.cellAutoSelectParams = params;
    
end

