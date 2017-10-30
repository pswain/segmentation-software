function slider_cb(cDisplay)
% slider_cb(cDisplay)
%
% slider call back for cTrapDisplayPlot. Shows cell outlines as green if
% they are part of cDisplay.cTimelapse.cellsToPlot or red if they are not
% (and will therefore not be extracted).

timepoint = get(cDisplay.slider,'Value');
timepoint=floor(timepoint);
alltraps=cDisplay.cTimelapse.returnTrapsTimepoint(cDisplay.traps,timepoint,cDisplay.channel);
trapInfo=cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo;

for j=1:size(alltraps,3)
    if ~isempty(trapInfo(cDisplay.traps(j)).cellLabel)
        % produces logical that shows if each cell is to be extracted by
        % cell index.
        to_extract=full(cDisplay.cTimelapse.cellsToPlot(cDisplay.traps(j),trapInfo(cDisplay.traps(j)).cellLabel))>0;
    else
        to_extract=false(length(trapInfo(cDisplay.traps(j)).cell),1);
    end

    image=alltraps(:,:,j);
    image=double(image);
    image=image/max(image(:))*.95;
    image=repmat(image,[1 1 3]);
    
    if trapInfo(cDisplay.traps(j)).cellsPresent
        seg_areas=[trapInfo(cDisplay.traps(j)).cell(:).segmented];
        seg_areas=full(seg_areas);
        seg_areas=reshape(seg_areas,[size(image,1) size(image,2) length(trapInfo(cDisplay.traps(j)).cell)]);
        seg_areas_not=max(seg_areas(:,:,~to_extract),[],3);
        seg_areas_tracked=max(seg_areas(:,:,to_extract),[],3);
        
    else
        seg_areas_not=false([size(image,1) size(image,2)]);
        seg_areas_tracked=false([size(image,1) size(image,2)]);
    end
    

    t_im=image(:,:,1);
    t_im(seg_areas_not)=1;
    image(:,:,1)=t_im;
    
    t_im_to_extract=image(:,:,2);
    t_im_to_extract(seg_areas_tracked)=1;
    image(:,:,2)=t_im_to_extract;
    
    set(cDisplay.subImage(j),'CData',image);
    set(cDisplay.subAxes(j),'CLimMode','manual');
    set(cDisplay.subAxes(j),'CLim',[min(image(:)) max(image(:))]);
    
end
set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint)]);
