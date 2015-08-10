function provideOffset(cExperiment,channel_offset,channel,positionsToIdentify)
%function provideOffset(cExperiment,channel_offset,channel,positionsToIdentify)
    
if nargin<4 || isempty(positionsToIdentify)
    positionsToIdentify=1:length(cExperiment.dirs);
end

if nargin<2 || isempty(channel_offset)
    
	offset_cell = inputdlg({'provide x offset(positive shifts image left):' ...
                                'provide y offset(positive shifts image up):'},...
                            'provide offset',...
                            1,...
                            {'0' '2'});
    channel_offset = [str2num(offset_cell{1}) str2num(offset_cell{2})];
end

%% Load timelapses
for i=1:length(positionsToIdentify)
    currentPos=positionsToIdentify(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    
    if i==1 && (nargin<3 || isempty(channel))
        [channel,ok] = listdlg('ListString',cTimelapse.channelNames,...
            'SelectionMode','multiple',...
            'Name','channel to offset',...
            'PromptString','Please select the channels to which to apply the offset correction');
        %uiwait();
        if ~ok
            return
        end
    end
    
    for channeli = 1:length(channel)
        cTimelapse.offset(channel(channeli),:) = channel_offset;
    end
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(currentPos);
end
