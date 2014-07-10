function getPixels(cData)
%Get the plot of (sorted) pixel brightness for a single cell&timepoint
%to be used as a diagnostic tool.
if isempty(cData.highlightedCell)
    return;
end
timepoint=get(cData.timepointSlider,'value');
cellID=cData.highlightedCell;
 try
     [~] =get(cData.individualCellFigure);
 catch
     cData.individualCellFigure=[];
 end
cTimelapse=cData.cTimelapse;
cellNum=find(cTimelapse.cTimepoint(timepoint).trapInfo.cellLabel==cellID);
outlines=cTimelapse.cTimepoint(timepoint).trapInfo.cell(cellNum).segmented;
% %Generate second (outer) circle to ensure there are no gaps in the cell
% %outline
% rad=cTimelapse.cTimepoint(timepoint).trapInfo.cell(cellNum).cellRadius;
% center=cTimelapse.cTimepoint(timepoint).trapInfo.cell(cellNum).cellCenter;
% theta=0:0.01:2*pi;
% coords=[double(center(2))+(rad+1)*cos(theta); double(center(1))+(rad+1)*sin(theta)];
% innerline=zeros(512,512);

% for i=1:length(coords(1,:))
%     innerline(floor(coords(1,i)),floor(coords(2,i)))=1;
% end
% innerline=innerline(1:512,1:512); %snip off the ends
%outlines=outlines+innerline;
outlinefilled=imfill(full(outlines),'holes');
[ypos,xpos]=find(full(outlines));


ymax=max(ypos);ymin=min(ypos);xmax=max(xpos);xmin=min(xpos);
imageIn=imread([cTimelapse.timelapseDir filesep cTimelapse.cTimepoint(timepoint).filename{2}]);
imageIn=double(imageIn)/double(max(imageIn(:)));
procImage=imageIn;
procImage(outlinefilled==0)=NaN;
procImage=procImage(ymin:ymax,xmin:xmax);
%figure('name',['Cell ' num2str(cellID) ', T' num2str(timepoint)]); imshow(procImage,[]);
procImage=flipud(procImage);
if isempty(cData.individualCellFigure)
    cData.individualCellFigure=figure('name',['Cell ' num2str(cellID) ', T' num2str(timepoint)]);
    [~, b]=contourf(procImage);
    cData.contourAxes=get(b,'parent'); %High level functions are annoying and tempremenatl
    caxis([0 1]);
    colorbar;
else
    %figure('name',['Cell ' num2str(cellID) ', T' num2str(timepoint)]);
    cla(cData.contourAxes);
    contourf(cData.contourAxes,procImage);
%     caxis([0 1]);
%     colorbar;
end

hold(cData.contourAxes,'on');


%add max5 and median markers
pixels=reshape(procImage,[numel(procImage),1]);
pixels(isnan(pixels))=[];
imagesort=sort(pixels,'descend');
max5=imagesort(1:5);
med=median(imagesort);
disp(max5);
disp(med);
disp((mean(max5))/med);
for i=1:5
    [y,x]=find(procImage==max5(i),1,'first');
    plot(cData.contourAxes,x,y,'dk','markerfacecolor','w');
    
end
[y,x]=find(procImage==med,1,'first');
plot(cData.contourAxes,x,y,'sk','markerfacecolor','w');
    
end