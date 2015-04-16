function extractSegAreaFl(cExperiment,positionsToTrack,channelStr,type,overwriteSeg)
if isempty(cExperiment.saveFolder)
    cExperiment.saveFolder=cExperiment.rootFolder;
end


if nargin<2
    positionsToTrack=find(cExperiment.posSegmented);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<4
    prompt(1) = {['Channel you would like to use to segment to replace the originally identified radius and segmentetation. ' ...
        ' The choices are whatever you used when you added channels (ie DIC, GFP, mCherry, etc)']};
    prompt(2)={'Type of projection or focusing to use (max, std, mean)'};
    dlg_title = 'Fluorescent Resegmentation';
    num_lines = 1;
    def(1) = {'GFP'};
    def(2)= {'max'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    channelStr=answer{1};
    
    type=answer{2};
end

if nargin<5
    overwriteSeg=false;
end

%% Run the tracking on the timelapse
for i=1:length(positionsToTrack)
    experimentPos=positionsToTrack(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    warning off
    cTimelapse.extractSegAreaFl(channelStr, type,overwriteSeg);
    warning on
    cExperiment.posTracked(experimentPos)=1;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end
