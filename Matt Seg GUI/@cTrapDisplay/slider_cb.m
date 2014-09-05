function slider_cb(cDisplay)
timepoint = get(cDisplay.slider,'Value');
timepoint=floor(timepoint);
alltraps=cDisplay.cTimelapse.returnTrapsTimepoint(cDisplay.traps,timepoint,cDisplay.channel);

trapInfo=cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo;
for j=1:size(alltraps,3)
    image=alltraps(:,:,j);
    image=double(image);
    image=image/max(image(:))*.95;
    image=repmat(image,[1 1 3]);
    
    segLabel=[];
    if ~isempty(trapInfo) && isfield(trapInfo(cDisplay.traps(j)),'cellsPresent') && trapInfo(cDisplay.traps(j)).cellsPresent
        seg_areas=[trapInfo(cDisplay.traps(j)).cell(:).segmented];
        seg_areas=full(seg_areas);
        seg_areas=reshape(seg_areas,[size(image,1) size(image,2) length(trapInfo(cDisplay.traps(j)).cell)]);
        cell_label = trapInfo(cDisplay.traps(j)).cellLabel;
        
        if isempty(cell_label) && trackOverlay
            
            fprintf('\n\n WARNING!! Cells not tracked \n\n')
            trackOverlay = false;
            
        end
                
    else
        seg_areas=zeros([size(image,1) size(image,2)])>0;
        segLabel=zeros([size(image,1) size(image,2)])>0;
        trackOverlay = false;
    end
    if trackOverlay
        segLabel = zeros(size(seg_areas));
        for i=1:size(seg_areas,3)
            
            segLabel(:,:,i) = cell_label(i)*imfill(seg_areas(:,:,i),'holes');
            
        end
        segLabel = max(segLabel,[],3);
        segLabel(1)=cDisplay.cTimelapse.cTimepoint(cDisplay.cTimelapse.timepointsToProcess(1)).trapMaxCell(cDisplay.traps(j));
        trackLabel=label2rgb(segLabel,'jet','w','shuffle');
        trackLabel=double(trackLabel);
        trackLabel=trackLabel/255;
        image=image.*trackLabel;
    else
        t_im=image(:,:,1);
        seg_areas=max(seg_areas,[],3);
        t_im(seg_areas)=1; %t_im(seg_areas)*3;
        image(:,:,1)=t_im;
    end
    set(cDisplay.subImage(j),'CData',image);
%     set(cDisplay.subAxes(j),'CLimMode','manual');
%     set(cDisplay.subAxes(j),'CLim',[min(image(:)) max(image(:))]);
    if cDisplay.trackOverlay
        %set(cDisplay.subImage(j),'HitTest','off'); %now image button function will work
        set(cDisplay.subImage(j),'HitTest','on'); %now image button function will work
    else
        set(cDisplay.subImage(j),'HitTest','on'); %now image button function will work
    end
    %     set(cDisplay.subAxes(j),'CLim',[0 1]);

    
    
end
set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint)]);

% title(cDisplay.subAxes(1),int2str(timepoint));
