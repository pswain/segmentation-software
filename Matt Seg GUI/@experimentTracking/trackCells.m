function trackCells(cExperiment,positionsToTrack,cellMovementThresh)

if isempty(cExperiment.saveFolder)
    cExperiment.saveFolder=cExperiment.rootFolder;
end


if nargin<2
    positionsToTrack=find(cExperiment.posSegmented);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3
    prompt = {'Max change in position and radius before a cell is classified as a new cell'};
    dlg_title = 'Tracking Threshold';
    num_lines = 1;
    def = {'8'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cellMovementThresh=str2double(answer{1});
end

%% Run the tracking on the timelapse
for i=1:length(positionsToTrack)
    experimentPos=positionsToTrack(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse.trackCells(cellMovementThresh);
    cExperiment.posTracked(experimentPos)=1;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end
