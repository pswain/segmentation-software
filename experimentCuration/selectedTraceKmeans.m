function [centroids, kmeansvector]=selectedTraceKmeans(matr, plothandle, ignoreCol)
matr=matr(:, setdiff(1:size(matr,2), ignoreCol))
centroids=[];
selectedCells= find(onOff2bin(get(get(get(plothandle, 'children'), 'children'), 'selected')));
   
x=get(get(get(plothandle, 'children'), 'children'), 'Ydata');


for i= 1: length(selectedCells)
    
    centroids(i,:)= x{selectedCells(i)};


end
centroids = centroids(:, setdiff(1:size(centroids,2), ignoreCol));
kmeansvector= kmeans(matr,[], 'start', centroids);



plotByGroupGeneral(matr, kmeansvector);

end