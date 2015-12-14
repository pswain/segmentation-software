function h=plotCellGroup(matrix, groupVector, groupToPlot)
h=figure;
plot(matrix(find(groupVector==groupToPlot), :)');
figure(gcf);
end