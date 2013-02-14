function displayTrapsTimelapse(cTimelapse,traps,channel,pause_duration)
%% Displays timelapse for a single trap
%This can either dispaly the primary channel (DIC) or a secondary channel
%that has been loaded. It uses the trap positions identified in the DIC
%image to display either the primary or secondary information. 


if nargin <4
    pause_duration=.05;
end

if nargin<3
    channel=1;
end

cTrap=cTimelapse.cTrapSize;
display.figure=figure(1);

dis_w=ceil(sqrt(length(traps)));
dis_h=ceil(length(traps)/dis_w);
image=cTimelapse.returnTrapsTimepoint(traps,1,channel);

% for i=1:size(image,3)
%     h_axes(i)=subplot(dis_h,dis_w,i);
% %     h_axes(i)=subplot('Position',[t_width*(i-1)+bb t_height*(i-1)+bb t_width t_height]);
%     h_fig(i)=subimage(image(:,:,i),i);
%     colormap(gray);
%     set(h_axes(i),'xtick',[],'ytick',[])
%     set(h_axes(i),'CLimMode','manual');
% end

t_width=.9/dis_w;
t_height=.9/dis_h;
bb=.1/max([dis_w dis_h]);
index=1;
for i=1:dis_w
    for j=1:dis_h
        %     h_axes(i)=subplot(dis_h,dis_w,i);
%         h_axes(index)=subplot('Position',[t_width*(i-1)+bb t_height*(j-1)+bb t_width t_height]);
        display.h_axes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb/2 t_width t_height]);
        display.h_fig(index)=subimage(image(:,:,i));
        colormap(gray);
        set(display.h_axes(index),'xtick',[],'ytick',[])
        set(display.h_axes(index),'CLimMode','auto')
        
        index=index+1;
        if index>size(image,3)
            break; end
    end
    
end



for i=1:length(cTimelapse.cTrapsLabelled(traps(1)).timepoint)
    image=cTimelapse.returnTrapsTimepoint(traps,i,channel);
    image=double(image);
    im_min=min(image(:));
    im_max=max(image(:))-im_min;
    for j=1:size(image,3)
        im=image(:,:,j);
%             im_min=min(im(:));

        im=im-im_min;
%             im_max=max(im(:));

        im=im*60/im_max;
        
%         im=uint8(im);
        set(display.h_fig(j),'CData',im);
        set(display.h_axes(j),'CLim',[0 100])
    
        
    end
    pause(pause_duration);
end

