cExperiment.rootFolder=uigetdir(pwd,'Select the Root of a single experimental set containing folders of multiple positions');
cExperiment.cellsToPlot=zeros(length(cExperiment.dirs),50,500)>0;

% folder='/Users/mcrane/TimelapseImages'

tempdir=dir(cExperiment.rootFolder);

cExperiment.dirs=cell(1);
index=1;
for i=1:length(tempdir)
    if tempdir(i).isdir 
        if index>2
            cExperiment.dirs{index-2}=tempdir(i).name;
        end
        index=index+1;
    end
end
%% Load timelapses
searchString{1}='DIC';
searchString{2}='GFP';
for i=1:length(cExperiment.dirs)
    cTimelapse=timelapseTraps([cExperiment.rootFolder '/' cExperiment.dirs{i}]);
    cTimelapse.loadTimelapse(searchString);
    cTrapSelectDisplay(cTimelapse,cCellVision);
    
    input('Hit Enter when done with this position');
    save([cExperiment.rootFolder '/' cExperiment.dirs{i}],'cTimelapse');
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
end
%% Identify cells trhough time
cCellVision.twoStageThresh=0;
method='twostage';
for i=1:length(cExperiment.dirs)
    load([cExperiment.rootFolder '/' cExperiment.dirs{i}]);
    cTrapDisplayProcessing(cTimelapse,cCellVision,method)
    cExperiment.lastSegmented=i;
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
    save([cExperiment.rootFolder '/' cExperiment.dirs{i}],'cTimelapse');
end
%%
%% Check that all desired cells are segmented
for i=1:cExperiment.lastSegmented
    load([cExperiment.rootFolder '/' cExperiment.dirs{i}]);
    cTrapDisplay(cTimelapse,cCellVision)
    input('Hit Enter when done with this position');
    save([cExperiment.rootFolder '/' cExperiment.dirs{i}],'cTimelapse');
end

%% Run the tracking on the timelapse
for experimentPos=1:length(cExperiment.dirs)
    load([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos}]);
    testtracking;
    cExperiment.lastSegmented=experimentPos;
    save([cExperiment.rootFolder '/cExperiment'],'cExperiment');
    save([cExperiment.rootFolder '/' cExperiment.dirs{experimentPos}],'cTimelapse');
end

%% Display the timelapse and select which cells to plot
cTrapDisplayPlot(cExperiment,cTimelapse,cCellVision)
%%
i=1
load([cExperiment.rootFolder '/' cExperiment.dirs{i}]);

%%
cTrapDisplayPlot(cExperiment,cTimelapse,cCellVision);

%%

