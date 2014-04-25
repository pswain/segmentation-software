function combineTracklets(cExperiment,positionsToTrack,params)



if nargin<2
    positionsToTrack=find(cExperiment.posSegmented);
%     positionsToTrack=1:length(cExperiment.dirs);
end

if nargin<3
        experimentPos=positionsToTrack(1);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);

    params.fraction=.1; %fraction of timelapse length that cells must be present or
    params.duration=3; %number of frames cells must be present
    params.framesToCheck=length(cTimelapse.timepointsProcessed);
    params.framesToCheckEnd=1;
    params.endThresh=2; %num tp after end of tracklet to look for cells
    params.sameThresh=4; %num tp to use to see if cells are the same
    params.classThresh=3.8; %classification threshold

    
    
    num_lines=1;clear prompt; clear def;
    prompt(1) = {'This combines individual tracks into larger tracks. Fraction of whole timelapse a cell must be present'};
    prompt(2) = {'OR - number of frames a cell must be present (Dec to look at short tracks, Inc to only look at long tracks)'};
    prompt(3) = {'Cell must appear in the first X frames (Dec if you only want to combine tracks that start early)'};
    prompt(4) = {'Cell must be present after frame X (Inc if you want to only look at tracks that stay past a certain time '};
    prompt(5) = {'New tracklet must appear within X frames (Dec to only look at new tracks that begin immediately after the previous track ended. Inc to be more lenient in search criteria)'};
    prompt(6) = {'Number of tracklet frames to compare (Compares the x,y,radius property of a cell to judge whether it is the same cell. More frames '};
    prompt(7) = {'Tracklet classification threshold'};
    dlg_title = 'Tracklet params';    
    def(1) = {num2str(params.fraction)};def(2) = {num2str(params.duration)};
    def(3) = {num2str(params.framesToCheck)};def(4) = {num2str(params.framesToCheckEnd)};
    def(5) = {num2str(params.endThresh)};
    def(6) = {num2str(params.sameThresh)};
    def(7) = {num2str(params.classThresh)};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    params.fraction=str2double(answer{1});
    params.duration=str2double(answer{2});
    params.framesToCheck=str2double(answer{3});
    params.framesToCheckEnd=str2double(answer{4});
    params.endThresh=str2double(answer{5});
    params.sameThresh=str2double(answer{6});
    params.clasThresh=str2double(answer{7});


end

%% Run the tracking on the timelapse
for i=1:length(positionsToTrack)
    experimentPos=positionsToTrack(i);
    load([cExperiment.saveFolder '/' cExperiment.dirs{experimentPos},'cTimelapse']);
    cTimelapse.combineTracklets(params);
    cExperiment.posTracked(experimentPos)=1;
    cExperiment.cTimelapse=cTimelapse;
    cExperiment.saveTimelapseExperiment(experimentPos);
end
