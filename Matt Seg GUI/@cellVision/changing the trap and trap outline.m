
cTimelapse=disp.cExperiment.returnTimelapse(1);
cCellVision=disp.cCellVision;

%%
tp=1;trap=4;
% cTimelapse.cTimepoint(tp).trapLocations(trap).xcenter=cTimelapse.cTimepoint(tp).trapLocations(trap).xcenter-2;
im=cTimelapse.returnTrapsTimepoint(trap,tp,1);
cCellVision.cTrap.trap2=im;
trap=2;
% cTimelapse.cTimepoint(tp).trapLocations(trap).xcenter=cTimelapse.cTimepoint(tp).trapLocations(trap).xcenter-2;
im=cTimelapse.returnTrapsTimepoint(trap,tp,1);
cCellVision.cTrap.trap1=im;

%%
trap=1;
im=cTimelapse.returnSegmenationTrapsStack(trap,tp);
im=max(im{1},[],3);

%%
im=cCellVision.cTrap.trap1;
figure;imshow(im,[])
bw=edge(im,'canny');
figure;imshow(bw,[]);
bwfill=imfill(bw);

bwfill=imopen(bwfill,strel('disk',1));
figure;imshow(bwfill,[])

cCellVision.cTrap.trapOutline=bwfill>0;
cCellVision.cTrap.contour=bwmorph(cCellVision.cTrap.trapOutline,'remove');

%%
cCellVision.identifyTrapOutline(cTimelapse,1)

cCellVision.cTrap.contour=bwmorph(cCellVision.cTrap.trapOutline,'remove');

%%
t=cCellVision.cTrap.trapOutline;