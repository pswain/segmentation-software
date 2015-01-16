function trapsTimelapse=returnTrapsTimelapse(cTimelapse,traps,channel)


if nargin<3
    channel=1;
end

cTrap=cTimelapse.cTrapSize;        
bb=max([cTrap.bb_width cTrap.bb_height])+10;

trapsTimelapse=zeros(cTrap.bb_height*2+1,cTrap.bb_width*2+1,length(cTimelapse.timepointsProcessed),length(traps));
for i=1:length(cTimelapse.timepointsProcessed);
    timepoint=i;
    trapsIm=cTimelapse.returnTrapsTimepoint(traps,timepoint,channel);
    
    for j=1:size(trapsIm,3)
        trapsTimelapse(:,:,i,j)=trapsIm(:,:,j);
    end
end
