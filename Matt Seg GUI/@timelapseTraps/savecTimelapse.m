function savecTimelapse(cTimelapse)

if strcmp(cTimelapse.timelapseDir,'ignore')
    oldFolder = cd('~');    
else
    oldFolder=cd(cTimelapse.timelapseDir);
end
[FileName,PathName,FilterIndex] = uiputfile('cTimelapse','Name of current timelapse') ;

save(fullfile(PathName,FileName),'cTimelapse');

cd(oldFolder);