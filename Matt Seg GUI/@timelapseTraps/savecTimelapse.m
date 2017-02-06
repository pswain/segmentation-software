function savecTimelapse(cTimelapse)
% mthod to save the cTimelapse
%
% probably defunct since all processing and storing is now done via
% experimentTracking

cTimelapse.temporaryImageStorage=[];
if strcmp(cTimelapse.timelapseDir,'ignore')
    oldFolder = cd('~');
else
    oldFolder=cd(cTimelapse.timelapseDir);
end
[FileName,PathName,FilterIndex] = uiputfile('cTimelapse','Name of current timelapse') ;

save(fullfile(PathName,FileName),'cTimelapse');

cd(oldFolder);
