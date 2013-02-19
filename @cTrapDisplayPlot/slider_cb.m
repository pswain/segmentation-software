function slider_cb(cDisplay)
timepoint = get(cDisplay.slider,'Value');
timepoint=floor(timepoint);
alltraps=cDisplay.cTimelapse.returnTrapsTimepoint(cDisplay.traps,timepoint,cDisplay.channel);
trapInfo=cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo;

for j=1:size(alltraps,3)
    tracked=full(cDisplay.cTimelapse.cellsToPlot(cDisplay.traps(j),trapInfo(cDisplay.traps(j)).cellLabel))>0;

    image=alltraps(:,:,j);
    image=double(image);
    image=image/max(image(:))*.95;
    image=repmat(image,[1 1 3]);
    
    segLabel=[];
    if trapInfo(cDisplay.traps(j)).cellsPresent
        seg_areas=[trapInfo(cDisplay.traps(j)).cell(:).segmented];
        seg_areas=full(seg_areas);
        seg_areas=reshape(seg_areas,[size(image,1) size(image,2) length(trapInfo(cDisplay.traps(j)).cell)]);
    else
        seg_areas=zeros([size(image,1) size(image,2)])>0;
        segLabel=zeros([size(image,1) size(image,2)])>0;
    end
    
    seg_areas_not=max(seg_areas(:,:,~tracked),[],3);
    seg_areas_tracked=max(seg_areas(:,:,tracked),[],3);
    
    %
    if cDisplay.trackOverlay
        if isempty(segLabel)
            segLabel=full(trapInfo(cDisplay.traps(j)).trackLabel);
        end
        segLabel(1)=cDisplay.cTimelapse.cTimepoint(1).trapMaxCell(j);
        trackLabel=label2rgb(segLabel,'jet','w','shuffle');
        trackLabel=double(trackLabel);
        trackLabel=trackLabel/255;
        image=image.*trackLabel;
%         image(trackLabel>0)=
    else
        %         t_im=image(:,:,1);
        %         seg_areas=max(seg_areas,[],3);
        %         t_im(seg_areas)=1; %t_im(seg_areas)*3;
        %         image(:,:,1)=t_im;
    end

    
    %
    t_im=image(:,:,1);
    t_im(seg_areas_not)=1;
    image(:,:,1)=t_im;
    
    t_im_tracked=image(:,:,2);
    t_im_tracked(seg_areas_tracked)=1;
    image(:,:,2)=t_im_tracked;
    
    set(cDisplay.subImage(j),'CData',image);
    set(cDisplay.subAxes(j),'CLimMode','manual');
    set(cDisplay.subAxes(j),'CLim',[min(image(:)) max(image(:))]);
    
end
set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint)]);

% title(cDisplay.subAxes(1),int2str(timepoint));
