function addTrapLabelSecondary(cDictionary,cTimelapse,trap_num_to_add)

traps_in_dictionary=length(cDictionary.cTrap);

i=trap_num_to_add;
cDictionary.cTrap(traps_in_dictionary+1).image=cTimelapse.returnSingleTrapTimelapse(i,'primary');
cDictionary.cTrap(traps_in_dictionary+1).class=logical(zeros(size(cDictionary.cTrap(traps_in_dictionary+1).image)));

trapTimelapse=cTimelapse.returnSingleTrapTimelapse(i,'secondary');
trapTimelapse=double(trapTimelapse);
trapTimelapse=trapTimelapse/max(trapTimelapse(:));
thresh=graythresh(trapTimelapse);
%     figure(1); hbw=gca; figure(2);htp=gca;
disp(['Trap ',int2str(i)])
for j=1:size(trapTimelapse,3)
    trapTimepoint=trapTimelapse(:,:,j);
    trapTimepoint=imfilter(trapTimepoint,fspecial('disk',3));
    bw=im2bw(trapTimepoint,thresh);
    %         imshow(bw,[],'Parent',hbw);
    %         imshow(trapTimepoint,[0 1],'Parent',htp);pause(.1);
    cDictionary.cTrap(traps_in_dictionary+1).class(:,:,j)=bw>0;
    cDictionary.labelledSoFar(traps_in_dictionary+1,j)=1;
end

traps_in_dictionary=traps_in_dictionary+1;
