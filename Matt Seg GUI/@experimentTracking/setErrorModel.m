function setErrorModel(cExperiment,ErrorModel,channel,positionsToIdentify)
% setErrorModel(cExperiment,ErrorModel,channel,positionsToIdentify) 
%
% ErrorModel is an object of the ErrorModel class
% chanel is an array of channels for which it applies
% rest is straightforward.
   
if nargin<2 ||isempty(ErrorModel)
    fprintf('\n\n Error Model must be provided\n\n')
    return
    
end
   
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
            'PromptString','Please select the channel to which to apply the error model');
        %uiwait();
        if ~ok
            return
        end
    end
    
    cTimelapse.ErrorModel{channel} = ErrorModel;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
