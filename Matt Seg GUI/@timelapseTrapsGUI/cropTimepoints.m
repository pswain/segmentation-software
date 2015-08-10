function cropTimepoints(cCellVisionGUI)

answer1=inputdlg('Starting Timepoint?')
answer2=inputdlg('Ending Timepoint?')

startTP=str2double(answer1{1});
endTP=str2double(answer2{1});

cCellVisionGUI.cTimelapse.cTimepoint=cCellVisionGUI.cTimelapse.cTimepoint(startTP:endTP);
