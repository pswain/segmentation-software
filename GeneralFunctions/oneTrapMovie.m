function oneTrapMovie(cTimelapse, trap, saveFolder,channel)
%Trap is number of the trap you want to look at
if nargin==2
saveFolder=uigetdir;
channel=1;
end
mkdir(saveFolder);
for t=1:length(cTimelapse.cTimepoint)
    im=cTimelapse.returnSingleTrapTimepoint(trap,t,channel);
    im=repmat(im,[1 1 3]);
    seg=full(cTimelapse.cTimepoint(t).trapInfo(trap).cell(1).segmented);
    for c=1:length(cTimelapse.cTimepoint(t).trapInfo(trap).cell)
        seg=seg+(full(cTimelapse.cTimepoint(t).trapInfo(trap).cell(c).segmented));
    end
    seg=seg.*2^16;
    seg=uint16(seg);
    im(:,:,2)=im(:,:,2)+seg;
    filename=[saveFolder filesep num2str(t) '.png'];
    imwrite(im, filename);
end