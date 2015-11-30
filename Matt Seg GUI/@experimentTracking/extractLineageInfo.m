function extractLineageInfo(cExperiment,positionsToExtract,params)

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
    params.motherDurCutoff=(.6);
    params.motherDistCutoff=2.1;
    params.budDownThresh=0;
    params.birthRadiusThresh=8;
    params.daughterGRateThresh=-1;
    
    
    num_lines=1;clear prompt; clear def;
    prompt(1) = {'Fraction of timelapse a mother must be present'};
    prompt(2) = {'Multiple of mother radius a daughter can be from the mother'};
    prompt(3) = {'Fraction of daughters that must be budded through the trap to be considered'};
    prompt(4) = {'Daughter birth radius cutoff thresh (less than)'};
        prompt(5) = {'Daughter growth rate (in radius pixels)'};

    
    dlg_title = 'Tracklet params';
    def(1) = {num2str(params.motherDurCutoff)};def(2) = {num2str(params.motherDistCutoff)};
    def(3) = {num2str(params.budDownThresh)};
    def(4) = {num2str(params.birthRadiusThresh)};
    def(5) = {num2str(params.daughterGRateThresh)};
    
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    params.motherDurCutoff=str2double(answer{1});
    params.motherDistCutoff=str2double(answer{2});
    params.budDownThresh=str2double(answer{3});
    params.birthRadiusThresh=str2double(answer{4});
    params.daughterGRateThresh=str2double(answer{5});
    
end



%% Run the tracking on the timelapse
for i=1:length(positionsToExtract)
    i
    experimentPos=positionsToExtract(i);
    cTimelapse=cExperiment.returnTimelapse(experimentPos);
    %load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    %
    cTimelapse.extractLineageInfo(params);

    
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end