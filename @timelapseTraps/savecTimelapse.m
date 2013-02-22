function savecTimelapse(cTimelapse)

oldFolder=cd(cTimelapse.timelapseDir);
[FileName,PathName,FilterIndex] = uiputfile('cTimelapse','Name of current timelapse') ;

save(fullfile(PathName,FileName),'cTimelapse');

cd(oldFolder);