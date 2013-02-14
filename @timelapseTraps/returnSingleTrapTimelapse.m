function trapTimelapse=returnSingleTrapTimelapse(cTimelapse,trap_num_to_show, channel)

if nargin<3
    channel=1;
end

cTrap=cTimelapse.cTrapSize;
for i=1:length(cTimelapse.cTimepoint(trap_num_to_show).timepoint)
    bb=max([cTrap.bb_width cTrap.bb_height])+10;
    y=cTimelapse.cTrapsLabelled(trap_num_to_show).ycenter(i) + bb;
    x=cTimelapse.cTrapsLabelled(trap_num_to_show).xcenter(i) + bb;
    image=cTimelapse.returnSingleTimepoint(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint(i),channel);
    bb_image=padarray(image,[bb bb],median(image(:)));
    temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
    trapTimelapse(:,:,i)=temp_im;
end
