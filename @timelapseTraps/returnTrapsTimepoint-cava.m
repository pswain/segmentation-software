function trapsTimepoint=returnTrapsTimepoint(cTimelapse,traps,timepoint,channel)

if nargin<4
    channel=1;
end

if strcmp(channel,'segmented')
    for j=1:length(traps)
        trapsTimepoint(:,:,:,j)=cTimelapse.cTrapsLabelled(j).segmented(:,:,timepoint);
    end
elseif strcmp(channel,'segDIC')
    cTrap=cTimelapse.cTrapSize;
    image=cTimelapse.returnSingleTimepoint(cTimelapse.cTrapsLabelled(traps(1)).timepoint(timepoint),1);
    bb=max([cTrap.bb_width cTrap.bb_height])+10;
    bb_image=padarray(image,[bb bb],median(image(:)));
    
    for j=1:length(traps)
        y=cTimelapse.cTrapsLabelled(traps(j)).ycenter(timepoint) + bb;
        x=cTimelapse.cTrapsLabelled(traps(j)).xcenter(timepoint) + bb;
        dic=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
        seg=cTimelapse.cTrapsLabelled(j).segmented(:,:,timepoint);
        dic(seg)=dic(seg)*1.5;
        trapsTimepoint(:,:,:,j)=repmat(dic,[1 1 3]);
    end
elseif strcmp(channel,'circleDIC')
    cTrap=cTimelapse.cTrapSize;
%     image=cTimelapse.returnSingleTimepoint(timepoint,1);
    image=cTimelapse.returnSingleTimepoint(cTimelapse.cTrapsLabelled(traps(1)).timepoint(timepoint),1);

    bb=max([cTrap.bb_width cTrap.bb_height])+10;
    bb_image=padarray(image,[bb bb],median(image(:)));
    trapsTimepoint=zeros(cTrap.bb_height*2+1,cTrap.bb_width*2+1,3,length(traps));
    for j=1:length(traps)
        y=cTimelapse.cTrapsLabelled(traps(j)).ycenter(timepoint) + bb;
        x=cTimelapse.cTrapsLabelled(traps(j)).xcenter(timepoint) + bb;
        dic=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
        
        circen=cTimelapse.cTrapsLabelled(traps(j)).cellCenters{timepoint};
        cirrad=cTimelapse.cTrapsLabelled(traps(j)).cellRadius{timepoint};
        
        nseg=32;
        temp_im=repmat(dic,[1 1 3]);
        for k=1:length(cirrad)
            x=circen(k,1);y=circen(k,2);r=cirrad(k);
            
            theta = 0 : (2 * pi / nseg) : (2 * pi);
            pline_x = round(r * cos(theta) + x);
            pline_y = round(r * sin(theta) + y);
            loc=find(pline_x>size(dic,2) | pline_x<1 | pline_y>size(dic,1) | pline_y<1);
            pline_x(loc)=[];pline_y(loc)=[];
            for i=1:length(pline_x)
                temp_im(pline_y(i),pline_x(i),1)=1.5*max(dic(:));
            end
        end
        trapsTimepoint(:,:,:,j)=temp_im;
    end
    trapsTimepoint=trapsTimepoint/max(trapsTimepoint(:));
elseif strcmp(channel,'DIC')
    cTrap=cTimelapse.cTrapSize;
    image=cTimelapse.returnSingleTimepoint(timepoint,1);
    bb=max([cTrap.bb_width cTrap.bb_height])+10;
    bb_image=padarray(image,[bb bb],median(image(:)));
    for j=1:length(traps)
        y=cTimelapse.cTrapsLabelled(traps(j)).ycenter(timepoint) + bb;
        x=cTimelapse.cTrapsLabelled(traps(j)).xcenter(timepoint) + bb;
        temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
        
        trapsTimepoint(:,:,:,j)=repmat(temp_im,[1 1 3]);
    end
elseif strcmp(channel,'FL')
    cTrap=cTimelapse.cTrapSize;
    image=cTimelapse.returnSingleTimepoint(timepoint,2);
    bb=max([cTrap.bb_width cTrap.bb_height])+10;
    bb_image=padarray(image,[bb bb],median(image(:)));
    for j=1:length(traps)
        y=cTimelapse.cTrapsLabelled(traps(j)).ycenter(timepoint) + bb;
        x=cTimelapse.cTrapsLabelled(traps(j)).xcenter(timepoint) + bb;
        temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
        
        trapsTimepoint(:,:,:,j)=repmat(temp_im,[1 1 3]);
    end
else
    cTrap=cTimelapse.cTrapSize;
    image=cTimelapse.returnSingleTimepoint(cTimelapse.cTrapsLabelled(traps(1)).timepoint(timepoint),channel);
    bb=max([cTrap.bb_width cTrap.bb_height])+10;
    bb_image=padarray(image,[bb bb],median(image(:)));
    for j=1:length(traps)
        y=cTimelapse.cTrapsLabelled(traps(j)).ycenter(timepoint) + bb;
        x=cTimelapse.cTrapsLabelled(traps(j)).xcenter(timepoint) + bb;
        trapsTimepoint(:,:,j)=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
    end
end
