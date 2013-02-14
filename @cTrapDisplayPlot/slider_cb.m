function slider_cb(cDisplay)
timepoint = get(cDisplay.slider,'Value');
timepoint=floor(timepoint);
alltraps=cDisplay.cTimelapse.returnTrapsTimepoint(cDisplay.traps,timepoint,cDisplay.channel);
for j=1:size(alltraps,3)
    tracked=full(cDisplay.cTimelapse.cellsToPlot(cDisplay.traps(j),cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(cDisplay.traps(j)).cellLabel))>0;

    image=alltraps(:,:,j);
    image=double(image);
    image=image/max(image(:))*.75;
    image=repmat(image,[1 1 3]);
    
    if cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(cDisplay.traps(j)).cellsPresent
        seg_areas=[cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(cDisplay.traps(j)).cell(:).segmented];
        seg_areas=full(seg_areas);
        seg_areas=reshape(seg_areas,[size(image,1) size(image,2) length(cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo(cDisplay.traps(j)).cell)]);
%         if sum(tracked(:))<length(tracked) && sum(tracked(:))>0
%             seg_areas_not=max(seg_areas(:,:,~tracked),[],3);
%             seg_areas_tracked=max(seg_areas(:,:,tracked),[],3);
%         elseif sum(tracked(:))==0
%             seg_areas_not=max(seg_areas,[],3);
%             seg_areas_tracked=zeros([size(image,1) size(image,2)])>0;
%         else
%             seg_areas_tracked=max(seg_areas,[],3);
%             seg_areas_not=zeros([size(image,1) size(image,2)])>0;
%         end
    else
        seg_areas=zeros([size(image,1) size(image,2)])>0;
%         seg_areas_not=seg_areas;
%         seg_areas_tracked=seg_areas;
    end
    
    seg_areas_not=max(seg_areas(:,:,~tracked),[],3);
    seg_areas_tracked=max(seg_areas(:,:,tracked),[],3);

    
    t_im=image(:,:,1);
    t_im_tracked=image(:,:,1);
    t_im_tracked(seg_areas_tracked)=1;
    t_im(seg_areas_not)=1;
    image(:,:,1)=t_im;
    image(:,:,2)=t_im_tracked;
    
    set(cDisplay.subImage(j),'CData',image);
    set(cDisplay.subAxes(j),'CLimMode','manual');
    set(cDisplay.subAxes(j),'CLim',[min(image(:)) max(image(:))]);
end
set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint)]);

% title(cDisplay.subAxes(1),int2str(timepoint));
