function setSegmentationChannels(cExperiment,channels_for_segment,positionsToAlter)
%setSegmentationChannels(cExperiment,channels_for_segment,positionsToAlter)
%sets the segmentation channels of all the positions selected to be the
%input segmentation_channels (or opens a dialog box). segmentation channels
%should be an array of numbers indicating the channels such as [1 3 2].
%These are then used in cCellVision and are expected to correspond to those
%in cCellVision model which can be seen in cCellVision model.
%assumes all positions entered have the same channels in the same order.
if nargin<3 || isempty(positionsToAlter)
    positionsToAlter=1:length(cExperiment.dirs);
end

button = 'OK';

if isempty(cExperiment.cCellVision)

    fprintf('\n please provide a cCellVision model first \n \n')
    return
else
    
if nargin<2 || isempty(channels_for_segment)
    
    channel_name_fields = {};
    channels_for_segment = zeros(1,length(cExperiment.cCellVision.training_channels));
    
    dialog_struct = struct('title','Segmentation Channel Selection',...
        'Description',['Select channels you want to use for the segmentation.'... 
        ' These should correspond to the channels used to train the SVM which'...
        ' are indicated in the description of each channel.']);
    for ci = 1:length(cExperiment.cCellVision.training_channels)
        
        channel_name_fields{ci} = sprintf('sc%d',ci);
        
        dialog_struct.(sprintf('forgotten_field_%d',ci)) =...
         struct('entry_name',...
                    {{sprintf('channel '' %s '' in training',cExperiment.cCellVision.training_channels{ci}),channel_name_fields{ci}}},...
                'entry_value',{cExperiment.channelNames});
        
    end
    
    % gui to show images from training.
    if ~isempty(cExperiment.cCellVision.trainingImageExample)
        dialog_struct.Description = [dialog_struct.Description,' A seperate figure should '...
        'be open showing you example images from the training'];
    f = figure;
    N_images = size(cExperiment.cCellVision.trainingImageExample,3);
    for n = 1:N_images
        subplot(1,N_images,n);
        imshow(cExperiment.cCellVision.trainingImageExample(:,:,n),[]);
        title(cExperiment.cCellVision.training_channels{n},'Interpreter','none');
    end
    end
    
	[settings button] = settingsdlg(dialog_struct);
    
    
    for ci = 1:length(cExperiment.cCellVision.training_channels)
        
        channels_for_segment(ci) = find(strcmp(settings.(channel_name_fields{ci}),cExperiment.channelNames),1);
        
    end
    
end

%% Load timelapses
if strcmp(button,'OK')
    for i=1:length(positionsToAlter)
        currentPos=positionsToAlter(i);
        cTimelapse = cExperiment.loadCurrentTimelapse(currentPos);
        cTimelapse.channelsForSegment = channels_for_segment;
        
        cExperiment.cTimelapse=cTimelapse;
        if i==length(positionsToAlter)
            cExperiment.saveTimelapseExperiment(currentPos);
        else
            cExperiment.saveTimelapse(currentPos);
        end
    end
    fprintf('\n channels for segmentation set \n\n')
else
    fprintf('\n CANCEL: No timelapse has been altered.\n\n')
end
end
end
