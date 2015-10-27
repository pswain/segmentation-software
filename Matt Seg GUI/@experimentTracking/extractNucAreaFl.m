function extractNucAreaFl(cExperiment,positionsToTrack,channelStr,type,flThresh)
if isempty(cExperiment.saveFolder)
    cExperiment.saveFolder=cExperiment.rootFolder;
end


if nargin<2 || isempty(positionsToTrack)
    positionsToTrack=find(cExperiment.posSegmented);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<4
    prompt(1) = {['Channel you would like to use to identify the size of the nucleus. ' ...
        ' The choices are whatever you used when you added channels (ie DIC, GFP, mCherry, etc)']};
    prompt(2)={'Type of projection or focusing to use (max, sum, mean)'};
    prompt(3)={'Fl threshold used to determine if Fl channel acquired properly'};
    dlg_title = 'Fluorescent Resegmentation';
    num_lines = 1;
    def(1) = {'mCherry'};
    def(2)= {'sum'};
    def(3)={'50'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    channelStr=answer{1};
    
    type=answer{2};
    flThresh=answer{3};
end

if nargin<5
    flThresh=[];
end

%% Run the tracking on the timelapse
for i=1:length(positionsToTrack)
    experimentPos=positionsToTrack(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
%     warning off
    cTimelapse.extractNucAreaFL(channelStr, type,flThresh);
    warning on
%     cExperiment.posTracked(experimentPos)=1;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end
