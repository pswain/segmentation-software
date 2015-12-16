function [centroids, selectedCell]=selectedCellVideo(cExperiment, plothandle, channel, videoName)
if nargin<4
    videoName='tempVideo.avi'
end
centroids=[];
selectedCells= find(onOff2bin(get(get(get(plothandle, 'children'), 'children'), 'selected')));


x=get(get(get(plothandle, 'children'), 'children'), 'Ydata');


for i= 1: length(selectedCells)
    
    
    %cExperiment.cellInf(2).mean
    selectedCell=length(x)-selectedCells(i)+1
    trapVideo(cExperiment, length(x)-selectedCells(i)+1, channel, videoName);


end

% kmeansvector= kmeans(cExperiment.cellInf(2).mean,[], 'start', centroids);
% 
% plotByGroup(cExperiment, kmeansvector)



end