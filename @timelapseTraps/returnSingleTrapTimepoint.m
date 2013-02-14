function trapTimepoint=returnSingleTrapTimepoint(cTimelapse,trap_num_to_show,timepoint,channel)

if nargin<4
    channel=1;
end
% 
% cTrap=cTimelapse.cTrapSize;
% 
% 
% i=timepoint;
% bb=max([cTrap.bb_width cTrap.bb_height])+10;
% y=cTimelapse.cTimepoint(i).trapLocations(trap_num_to_show).ycenter + bb;
% x=cTimelapse.cTimepoint(i).trapLocations(trap_num_to_show).xcenter + bb;
% 
% % y=cTimelapse.cTrapsLabelled(trap_num_to_show).ycenter(i) + bb;
% % x=cTimelapse.cTrapsLabelled(trap_num_to_show).xcenter(i) + bb;
% image=cTimelapse.returnSingleTimepoint(timepoint,channel);
% bb_image=padarray(image,[bb bb]);
% temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
% temp_im(temp_im==0)=median(temp_im(:));
% 
% trapTimepoint=temp_im;

trapTimepoint=cTimelapse.returnTrapsTimepoint(trap_num_to_show,timepoint,channel);

