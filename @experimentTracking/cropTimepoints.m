function cropTimepoints(cExperiment,positionsToCrop)


answer1=inputdlg('Starting Timepoint?');
answer2=inputdlg('Ending Timepoint?');

startTP=str2double(answer1{1});
endTP=str2double(answer2{1});

if nargin<2
    positionsToCrop=1:length(cExperiment.dirs);
end

for i=1:length(positionsToCrop)
    currentPos=positionsToCrop(i);
    load([cExperiment.rootFolder '/' cExperiment.dirs{currentPos},'cTimelapse']);
    cTimelapse.cTimepoint=cTimelapse.cTimepoint(startTP:endTP);
    
    cExperiment.saveTimelapseExperiment(currentPos);   
    clear cTimelapse;
end
