function extractSegAreaFl(cExperiment,positionsToTrack,channelStr,type,overwriteSeg)
% extractSegAreaFl(cExperiment,positionsToTrack,channelStr,type,overwriteSeg)
%
% channelStr            :   string of which channel to use for getting
%                           fluorescent area - should be one of those in
%                           cTimelapse.channelNames
% type                  :   type to handle stacks passed to returnTrapsTimepoint (min/max/std)
% overwriteSeg          :   boolean :
%                           true - replace the cell outline
%                           with the one found from this method running
%                           active contour method on fluorescent image.
%                           false - keep original cell outline and just
%                           calculate radiusFL.
%
% runs extractSegAreaFl(channelStr, type,overwriteSeg) for each cTimelapse.
% see this method for details. Roughly, it applies an active contour method
% (matlabs active contour with chan vese) to the fluorescent image
% specified by channelStr and either both populates the radiusFl field of
% trapInfo.cell and puts a new cell outline in the segmented field or just
% populates radiusFl field depending on overwriteSeg.
%
% If overwriting outlines it also changes cTimelapse.offset to all zeros.
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
    cTimelapse = cExperiment.loadCurrentTimelapse(experimentPos);
    warning off
    cTimelapse.extractSegAreaFl(channelStr, type,overwriteSeg);
    warning on
    cExperiment.posTracked(experimentPos)=1;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end
