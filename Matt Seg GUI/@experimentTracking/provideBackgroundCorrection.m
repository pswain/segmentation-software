function provideBackgroundCorrection(cExperiment,BackgroundCorrection,channel,positionsToIdentify)
   %provideBackgroundCorrection(cExperiment,BackgroundCorrection,channel,positionsToIdentify)
   
if nargin<4 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end



%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    
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
