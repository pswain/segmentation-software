function displaySingleTrapTimelapse(cTimelapse,trap_num_to_show,channel,pause_duration)
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
    figure(1);

for i=1:length(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint)
    image=cTimelapse.returnSingleTrapTimepoint(trap_num_to_show,i,channel);
    imshow(image,[]);pause(pause_duration);
end

        
%     case 'secondaryoverlay'
%         %The below isn't completed and needs to be finished
%         timelapse_primarymax=max(max([cTimelapse.cTimepoint.image]));
%         timelapse_secondarymax=max(max([cTimelapse.cTimepoint.secondaryImage]));
%         for i=1:length(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint)
%             bb=max([cTrap.bb_width cTrap.bb_height])+10;
%             y=cTimelapse.cTrapsLabelled(trap_num_to_show).ycenter(i) + bb;
%             x=cTimelapse.cTrapsLabelled(trap_num_to_show).xcenter(i) + bb;
%             bb_image_primary=padarray(cTimelapse.cTimepoint(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint(i)).image,[bb bb]);
%             temp_im_primary=bb_image_primary(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
%             temp_im_primary=uint8(double(temp_im_primary)*255/double(timelapse_primarymax));
%             bb_image_secondary=padarray(cTimelapse.cTimepoint(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint(i)).secondaryImage,[bb bb]);
%             temp_im_secondary=bb_image_secondary(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
%             temp_im_secondary=uint8(double(temp_im_secondary)*255/double(timelapse_secondarymax));
%             
%             imshow(temp_im_primary);title(['Timepoint ' int2str(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint(i))]);
%             % Make a truecolor all-green image.
%             green = cat(3, zeros(size(temp_im_primary)), ones(size(temp_im_primary)), zeros(size(temp_im_primary)));
%             hold on
%             h = imshow(green);
%             hold off
%             set(h, 'AlphaData', temp_im_secondary)
% 
% %             imshow(temp_im,[0 timelapse_max]);
%             pause(pause_duration);
%         end
%         close


