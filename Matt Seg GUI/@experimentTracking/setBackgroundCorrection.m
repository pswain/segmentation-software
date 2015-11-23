function setBackgroundCorrection(cExperiment,BackgroundCorrection,channel,positionsToIdentify)
%setBackgroundCorrection(cExperiment,BackgroundCorrection,channel,positionsToIdentify)
%
% set the flat field correction for each cTimelapse specified by
% positionsToIdentify
%
% BackgroundCorrection  :   Flat field correction: an image of the size of
%                           the images extracted.Image are dot multipled by
%                           this image before being returned by
%                           returnTimepoint.
% channel               :   array of channel indices which should have this
%                           multiplication applied.

   
if nargin<4 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end



%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    cTimelapse = cExperiment.loadCurrentTimelapse(currentPos);
    
    if i==1 && (nargin<3 || isempty(channel))
        [channel,ok] = listdlg('ListString',cTimelapse.channelNames,...
            'SelectionMode','single',...
            'Name','channel to correct',...
            'PromptString','Please select the channel to which to apply the background correction');
        %uiwait();
        if ~ok
            return
        end
    end
    
    cTimelapse.BackgroundCorrection{channel} = BackgroundCorrection;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
