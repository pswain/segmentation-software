function selectCellsToPlotAutomatic(cExperiment,positionsToCheck,params)
if nargin<2
    positionsToCheck=find(cExperiment.posTracked);
    %     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3 || isempty(params)
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
end

if size(cExperiment.cellsToPlot,3)>1
    cExperiment.cellsToPlot=cell(1);
    for i=1:length(cExperiment.posTracked)
        cExperiment.cellsToPlot{i}=sparse(zeros(1,1));
    end
end

%for backcompatibility with scripts that don't use this parameter
if ~isfield(params,'maximumNumberOfCells')
    params.maximumNumberOfCells = Inf;
end

%% Run the tracking on the timelapse

% Start logging protocol

cExperiment.logger.add_arg('Fraction of timelapse that cells are present for',params.fraction);
cExperiment.logger.add_arg('Number of frames a cell must be present',params.duration);
cExperiment.logger.add_arg('Cell must appear by frame',params.framesToCheck);
cExperiment.logger.add_arg('Cell must still be present by frame',params.framesToCheckEnd);
cExperiment.logger.add_arg('Maximum number of cells',params.maximumNumberOfCells);
cExperiment.logger.start_protocol('autoselecting cells',length(positionsToCheck));

try

    for i=1:length(positionsToCheck)
        if params.maximumNumberOfCells>=0
            experimentPos=positionsToCheck(i);
            cTimelapse=cExperiment.returnTimelapse(experimentPos);
            cTimelapse.automaticSelectCells(params);
            params.maximumNumberOfCells = max(params.maximumNumberOfCells - full(sum(cTimelapse.cellsToPlot(:))),0);
            cExperiment.cTimelapse=cTimelapse;
            cExperiment.cellsToPlot{i}=cTimelapse.cellsToPlot;
            %         cExperiment.saveTimelapseExperiment(experimentPos);
            if i==length(positionsToCheck)
                cExperiment.saveTimelapseExperiment(experimentPos);
            else
                cExperiment.saveTimelapse(experimentPos);
            end
        end
    end

% Finish logging protocol
cExperiment.logger.complete_protocol;
catch err
    cExperiment.logger.protocol_error;
    rethrow(err);
end

end