function trapTimepoint=returnSingleTrapTimepoint(cTimelapse,trap_num_to_show,timepoint,channel)

if nargin<4
    channel=1;
end

cTrap=cTimelapse.cTrapSize;


i=timepoint;
bb=max([cTrap.bb_width cTrap.bb_height])+10;
y=cTimelapse.cTrapsLabelled(trap_num_to_show).ycenter(i) + bb;
x=cTimelapse.cTrapsLabelled(trap_num_to_show).xcenter(i) + bb;
image=cTimelapse.returnSingleTimepoint(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint(i),channel);
bb_image=padarray(image,[bb bb],median(image(:)));
trapTimepoint=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);

