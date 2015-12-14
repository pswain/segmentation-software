function [handles, numGroups, colors]=plotByGroup(cExperiment, groupVector, cellchan, bgchan)


matrix=full(cExperiment.cellInf(cellchan).mean);

bgmatrix=full(cExperiment.cellInf(bgchan).imBackground);
maxmeans=[];
radiusmatrix=full(cExperiment.cellInf(cellchan).radius);
fig1=figure;
tsmeansFigure  =      subplot(3,2,1);    %plot(NaN)                %=subplot(3,2,1);
    %plot(NaN)                %=subplot(3,2,2);
tsRadiusFigure =      subplot(3,2,3);    %plot(NaN)                %=subplot(3,2,3);
tsRampMeansFigure =    subplot(3,2,4);   %plot(NaN)                %=subplot(3,2,4);
tsAllCellsFigure  =     subplot(3,2,5);  %plot(NaN)                %=subplot(3,2,5);
tsAllCellsRampFigure=   subplot(3,2,6);  %plot(NaN)                %=subplot(3,2,6);
cellNumFigure  =      subplot(3,2,2);
set(tsmeansFigure, 'Parent', fig1);
set(tsRadiusFigure, 'Parent', fig1);
set(tsRampMeansFigure, 'Parent', fig1);
set(tsAllCellsFigure , 'Parent', fig1);
set(tsAllCellsRampFigure, 'Parent', fig1);
set(cellNumFigure, 'Parent', fig1);


% h=axes;
% set(h, 'Parent', fig2);
% fig3=figure;
% g=axes;
% set(g, 'Parent', fig3);



numGroups= unique(groupVector);
numGroups=numGroups(find(isnan(numGroups)==0));
numberlist=[];
sizeList=[];
nonZeroMeans=[];
nonZeroStds=[];
colors=lines(20);
greens=0;
blues=.2;
for i= 1: length(numGroups)
    
    
    plot(tsmeansFigure, mean(matrix(find(groupVector==numGroups(i))   ,:))', 'Color', colors(i,:), 'LineWidth', 3);
    subplot(tsmeansFigure);
    %boundedline((1:size(matrix,2))', nonzeroColMean(matrix(find(groupVector==numGroups(i))   ,:))',nonZeroColStd(matrix(find(groupVector==numGroups(i))   ,:))', 'alpha');
   nonZeroMeans(i,:)=nonzeroColMean(matrix(find(groupVector==numGroups(i))   ,:));
   nonZeroStds(:,[1 2],i)=repmat(nonZeroColStd(matrix(find(groupVector==numGroups(i))   ,:))',1,2)
    
%     axis([0 180 0 800])
    hold(tsmeansFigure, 'on');
    plot(tsAllCellsFigure, matrix(find(groupVector==numGroups(i))   ,:)', '.', 'Color', colors(i,:), 'MarkerSize', 5.8) %,'LineWidth', 1);
         hold(tsAllCellsFigure, 'on');  
       plot(tsAllCellsRampFigure, bgmatrix(find(groupVector==numGroups(i))   ,:)', '.','Color', colors(i,:), 'MarkerSize', 5.8) %,'LineWidth', 1);
      hold(tsAllCellsRampFigure, 'on');
    plot(tsRampMeansFigure, nonzeroColMean(bgmatrix(find(groupVector==numGroups(i))   ,:))', 'Color', colors(i,:), 'LineWidth', 3);
    maxmeans(i)=max(nonzeroColMean(matrix(find(groupVector==numGroups(i))   ,:)))
    hold(tsRampMeansFigure, 'on');
    
   % plot(tsRadiusFigure, nonzeroColMean(radiusmatrix(find(groupVector==numGroups(i))   ,:))', '.','Color', [i/length(numGroups) greens  blues]     )%, 'LineWidth', 3);
    plot(tsRadiusFigure, nonzeroColMean(radiusmatrix(find(groupVector==numGroups(i))   ,:))', '.','Color', colors(i,:)    )%, 'LineWidth', 3);
    
    hold(tsRadiusFigure', 'on');
   % hold (g, 'on');
    numberlist(i)=sum(groupVector==numGroups(i));
   %sizeList(i)=  sum(sum(areamatrix(find(groupVector==numGroups(i))   ,:)))/sum(groupVector==numGroups(i));
end

subplot(tsmeansFigure);
tsmeansFigure=boundedline((1:size(matrix,2))', nonZeroMeans, repmat(nonZeroStds,1,1,2), 'alpha', 'cmap', colors, 'transparency', .5);
%h=boundedline((1:size(matrix,2))', nonZeroMeans, repmat(nonZeroStds,1,1,2), 'alpha', 'cmap', colors, 'transparency', .5);

axis([0 size(matrix,2) 0 max(max(matrix))]);
try
plot(tsmeansFigure,nonzeroColMean(bgmatrix)/max(mean(bgmatrix))*max(maxmeans), 'Color', [0 1 0], 'LineWidth', 3);
end

title( 'Cell average over time per group');
legend(num2str(numGroups));
hold off;


subplot(cellNumFigure)
diffColorBars(numberlist, colors);  


title(cellNumFigure, 'Number of cells in each group')
title(tsRadiusFigure, 'Average cell radius over time');
title(tsRampMeansFigure, 'Average glucose medium label intensity (cy5)');
title(tsAllCellsFigure, 'Mean fluorescence per cell over time');
title(tsAllCellsRampFigure, 'Average glucose medium label intensity (cy5) per cell');



figure(gcf);
 handles= [ tsmeansFigure;  cellNumFigure;   tsRadiusFigure;  tsRampMeansFigure; tsAllCellsFigure;  tsAllCellsRampFigure];
    
end

