function setChannelOffset(cExperiment,positionsToExtract,offset)

%method is either 'overwrite' or 'update'. If overwrite, it goes through
%all of the cellsToPlot and extracts the information from the saved
%Timelapses. If method is 'update', it finds the cells that have been added
%to the cellsToPlot and adds their inf to the cellInf, and removes those
%that have been removed.



if nargin<2
    positionsToExtract=find(cExperiment.posTracked);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3
    load([cExperiment.saveFolder '/' cExperiment.dirs{1},'cTimelapse']);

    num_lines=1;
    dlg_title = 'ChannelOffsets?';
    def=[];prompt=[];
    for i=1:size(cTimelapse.offset,1)
        def{i} = num2str(cTimelapse.offset(i,:));
        prompt{i} = ['offset channel ' num2str(i)];
    end
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    for i=1:size(cTimelapse.offset,1)
        offset(i,:)=str2num(answer{i});
    end
end

%% Run the tracking on the timelapse
for i=1:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    %
    cTimelapse.offset=offset;

    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end