function trap_image = returnWholeTrapImage(cTimelapse,cCellVision,timepoint)
% trapOutline = returnWholeTrapImage(cTimelapse,cCellVision,timepoint)
%
% returns an image (double) of the size cTimelapse.imSize with a trap outline at
% every trap location. Currently just places the trap outline from
% cCellVision at every trap location stored in cTimelapse.
%
% WARNING: currently this only gives trap pixels for the traps being
% tracked, so any non-tracked traps will not be blotted out.

cTrap=cTimelapse.cTrapSize;
bb=max([cTrap.bb_width cTrap.bb_height])+100;
trap_image=zeros(cTimelapse.imSize + bb);

traps = 1:length(cTimelapse.cTimepoint(timepoint).trapInfo);

for j=traps
    y=round(cTimelapse.cTimepoint(timepoint).trapLocations(j).ycenter + bb);
    x=round(cTimelapse.cTimepoint(timepoint).trapLocations(j).xcenter + bb);
    trap_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width) = cCellVision.cTrap.trapOutline;
end
trap_image = trap_image((1:cTimelapse.imSize(1))+bb,(1:cTimelapse.imSize(2))+bb);

end

function just_to_test(no_input)
% Test section

%% assumes a cTimelapse and cCellvision is loaded
tps = [1 10 30];
for tp=tps
im = double(cTimelapse.returnSingleTimepoint(tp,1));
trap_im = cTimelapse.returnWholeTrapImage(cCellVision,tp);
imshow(OverlapGreyRed(im,trap_im,[],[],true),[]);
pause
end
end

