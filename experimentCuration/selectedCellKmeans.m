function [centroids, kmeansvector, handles]=selectedCellKmeans(cExperiment, plothandle, cellchan, bgchan)

centroids=[];
selectedCells= find(onOff2bin(get(get(get(plothandle, 'children'), 'children'), 'selected')));

if(bgchan==0)
    
    bgchan=cellchan;
    
end

    
x=get(get(get(plothandle, 'children'), 'children'), 'Ydata');


for i= 1: length(selectedCells)
    
    centroids(i,:)= x{selectedCells(i)};


end

kmeansvector= kmeans(cExperiment.cellInf(cellchan).mean,[], 'start', centroids);

handles=plotByGroup(cExperiment, kmeansvector, cellchan, bgchan);



end