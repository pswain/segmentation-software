function setChannelOffset(cExperiment,positionsToExtract,offset)
%setChannelOffset(cExperiment,positionsToExtract,offset)
% sets the offset field for all cTimelapse objects in the cExperiment
% class.
%offset is an array as in cTimelapse. Can leave blank and write by GUI.


if nargin<2
    positionsToExtract=1:length(cExperiment.dirs);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3
    load([cExperiment.saveFolder '/' cExperiment.dirs{1},'cTimelapse']);

    num_lines=1;
    dlg_title = 'ChannelOffsets?';
    def=[];prompt=[];
    for i=1:size(cTimelapse.offset,1)
        def{i} = num2str(cTimelapse.offset(i,:));
        prompt{i} = ['offset channel ' num2str(i) ' : ' cTimelapse.channelNames{i}];
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    for i=1:size(cTimelapse.offset,1)
        offset(i,:)=str2num(answer{i});
    end
end

%% Run the tracking on the timelapse
for i=1:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    load([cExperiment.saveFolder filesep cExperiment.dirs{experimentPos},'cTimelapse']);
    %
    cTimelapse.offset=offset;

    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end

fprintf('finished setting offsets\n')