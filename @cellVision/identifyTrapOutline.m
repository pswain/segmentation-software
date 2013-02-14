function identifyTrapOutline(cCellVision,cTimelapse,trapNum)

%% Identify the trap outline
%This function extracts the outline of the trap by using the timelapse of a
%single tracked trap. It filters the trap using a difference of gaussians,
%and then extracts the edges of the image. The PDMS edges have a more
%pronounced edge and thus it is able to distinguish between the pdms and
%the cells. Doing this throughout the entire timelapse, it then takes the
%median value through time to determine the location of the traps.

if ~isempty(cCellVision.cTrap)
    trap=[];
    trap(:,:,1)=cCellVision.cTrap.trap1;
    trap(:,:,2)=cCellVision.cTrap.trap2;
    
    se2=strel('disk',2);
    se3=strel('disk',3);
    
    filt_im=[];im_fill=[];
    for i=1:2
        im=trap(:,:,i);
        %     temp_im=stdfilt(im,true(3));
        [im_edge thresh]=edge(im,'canny');
        %         [edge_im thresh]=edge(im,'canny',thresh*.8);
        %     temp_im=temp_im/max(temp_im(:));
        %     thresh=graythresh(temp_im)*1.5;
        
        %     temp_im=im2bw(temp_im,thresh);
        %     imbw=imclose(temp_im,se2);
        h=figure('Name','Select the center of each trap and hit enter');
        im_fill(:,:,i)=imfill(im_edge);
        close(h);
        im_fill(:,:,i)=imopen(im_fill(:,:,i),se2);
    end
    
    imflat=sum(im_fill,3)>1;
    h=figure;imshow(imflat,[]);title('Final Trap Outline');
    uiwait();
    
    cCellVision.cTrap.trapOutline=imflat;
else
    errordlg('There are no traps in this timelapse');
end
