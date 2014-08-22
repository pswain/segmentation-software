
params=struct('fraction',0.8,'duration',32,'framesToCheck',1,'framesToCheckEnd',37);
timelapse.cTimelapse.trackCells(30)
timelapse.cTimelapse.automaticSelectCells(params)
timelapse.cTimelapse.extractCellData