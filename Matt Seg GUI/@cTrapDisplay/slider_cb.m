function slider_cb(cDisplay)
% slider_cb(cDisplay)
%
% called when slider value changes or when a cell is added or removed.
% takes timepoint to be floor(cDisplay.slider.Value)
% updates images of cells and outlines, with outlines red or coloured by
% cell label for cDisplay.trackOverlay false or true respectively.
timepoint = get(cDisplay.slider,'Value');
timepoint=floor(timepoint);
alltraps=cDisplay.cTimelapse.returnTrapsTimepoint(cDisplay.traps,timepoint,cDisplay.channel);

trapInfo=cDisplay.cTimelapse.cTimepoint(timepoint).trapInfo;
for j=1:size(alltraps,3)
    trackOverlay = cDisplay.trackOverlay;
    image=alltraps(:,:,j);
    image=double(image);

    image=image/max(image(:))*.95;
    image=repmat(image,[1 1 3]);
    
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
        trackOverlay = false;
    end
    
    if trackOverlay
        segLabel = zeros(size(seg_areas));
        for i=1:size(seg_areas,3)
            
            segLabel(:,:,i) = cell_label(i)*seg_areas(:,:,i);
            
        end
        segLabel = max(segLabel,[],3);
        %shuffle colours so adjacent cells don't look super similar.
        %setting first point of segLabel to trapMaxCell ensures this is
        %consistent across all images.
        segLabel(1)=cDisplay.cTimelapse.cTimepoint(cDisplay.cTimelapse.timepointsToProcess(1)).trapMaxCell(cDisplay.traps(j));
        trackLabel=label2rgb(segLabel,'jet','w','shuffle');
        trackLabel=double(trackLabel);
        trackLabel=trackLabel/255;
        image=image.*trackLabel;
    else
        t_im=image(:,:,1);
        seg_areas=max(seg_areas,[],3);
        t_im(seg_areas)=1; 
        image(:,:,1)=t_im;
    end
    set(cDisplay.subImage(j),'CData',image);
    if cDisplay.trackOverlay
        set(cDisplay.subImage(j),'HitTest','on'); %now image button function will work
    else
        set(cDisplay.subImage(j),'HitTest','on'); %now image button function will work
    end
   
    
    
end
set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint)]);

