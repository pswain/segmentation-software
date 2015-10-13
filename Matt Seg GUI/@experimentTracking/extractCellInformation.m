function extractCellInformation(cExperiment,positionsToExtract,type,channels, cellSegType)
% extractCellInformation(cExperiment,positionsToExtract,type,channels)

%If the 3rd input (type) is the string 'not determined' then the software
%will run a dialog to get this info from the user. This was done to allow
%the 4th input (channels) to come from a calling function (extractData in the GUI)
%when the type is not yet known.

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
    type='not determined';
end

if strcmp(type,'not determined')
    num_lines=1;
    dlg_title = 'What to extract?';
    prompt = {['All Params using max projection (max), std focus (std), mean focus (mean), using all three measures (all), or basic (basic)' ...
        ' the basic measure only compiles the x, y locations of cells along with the estimated radius so it is much faster, but less informative.']};    def = {'max'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    type=answer{1};
end

if nargin<5 || isempty(cellSegType)
    cellSegType='segmented';
end

%% Run the tracking on the timelapse
for i=1:length(positionsToExtract)
    experimentPos=positionsToExtract(i);
    %
    cTimelapse=cExperiment.returnTimelapse(experimentPos);

    %load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    %
    
    if nargin<4 || isempty(channels)
        channels = 1:length(cTimelapse.channelNames);
    end
    
    switch type
        case {'max','all','std'} 
            cTimelapse.extractCellData(type,channels,cellSegType);
        case {'b','basic'}
            cTimelapse.extractCellParamsOnly();
    end

    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end