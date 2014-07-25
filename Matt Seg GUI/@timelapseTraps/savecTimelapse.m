function savecTimelapse(cTimelapse,PathName,FileName)

oldFolder=cd(cTimelapse.timelapseDir);
[FileName,PathName,FilterIndex] = uiputfile('cTimelapse','Name of current timelapse') ;

save(fullfile(PathName,FileName),'cTimelapse');

cd(oldFolder);