function trapsTimelapse=returnTrapsTimelapse(cTimelapse,traps,channel)


if nargin<3
    channel=1;
end

cTrap=cTimelapse.cTrapSize;        
bb=max([cTrap.bb_width cTrap.bb_height])+10;

trapsTimelapse=zeros(cTrap.bb_height*2+1,cTrap.bb_width*2+1,length(cTimelapse.cTrapsLabelled(traps(1)).timepoint),length(traps));
for i=1:length(cTimelapse.cTrapsLabelled(traps(1)).timepoint)
    for j=1:length(traps)
        trap_num_to_show=traps(j);
        y=cTimelapse.cTrapsLabelled(trap_num_to_show).ycenter(i) + bb;
        x=cTimelapse.cTrapsLabelled(trap_num_to_show).xcenter(i) + bb;
        image=cTimelapse.returnSingleTimepoint(cTimelapse.cTrapsLabelled(trap_num_to_show).timepoint(i),channel);
        bb_image=padarray(image,[bb bb],median(image(:)));
        temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
        trapsTimelapse(:,:,i,j)=temp_im;
    end
end
