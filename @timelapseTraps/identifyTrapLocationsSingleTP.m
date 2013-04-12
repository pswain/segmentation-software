function [trapLocations trap_mask]=identifyTrapLocationsSingleTP(cTimelapse,timepoint,cCellVision,trapLocations)

%% For each timepoint, identify the locations of the traps
%Go trhough each image in the timepoint object, and extract the locations
%of the traps using the identifyCellTrapsTimepoint function

%pass the trapLocations matrix from t-1 for the calculation of t cc. Uses the mask of
%the traps to increase the likelihood of finding the same trap again.
cTrap=cCellVision.cTrap;
% cTrap.trap1=imresize(cTrap.trap1,cCellVision.pixelSize/cTimelapse.pixelSize);
% cTrap.trap2=imresize(cTrap.trap2,cCellVision.pixelSize/cTimelapse.pixelSize);

% try
% cTrap.trap1=imresize(cTrap.trap1,cTimelapse.magnification/cCellVision.magnification);
% cTrap.trap2=imresize(cTrap.trap2,cTimelapse.magnification/cCellVision.magnification);
% catch
%     cTrap.trap1=imresize(cTrap.trap1,cCellVision.pixelSize/cTimelapse.pixelSize);
% cTrap.trap2=imresize(cTrap.trap2,cCellVision.pixelSize/cTimelapse.pixelSize);
% end

cTrap.bb_width=ceil((size(cTrap.trap1,2)-1)/2);
cTrap.bb_height=ceil((size(cTrap.trap1,1)-1)/2);

d1=size(cTrap.trap1,1)-(cTrap.bb_height*2+1);
d2=size(cTrap.trap1,2)-(cTrap.bb_width*2+1);

if d1>0
    cTrap.trap1=padarray(cTrap.trap1,[d1 0],median(cTrap.trap1(:)),'post');
    cTrap.trap2=padarray(cTrap.trap2,[d1 0],median(cTrap.trap2(:)),'post');
end
if d2>0
    cTrap.trap1=padarray(cTrap.trap1,[0 d2],median(cTrap.trap1(:)),'post');
    cTrap.trap2=padarray(cTrap.trap2,[0 d2],median(cTrap.trap2(:)),'post');
end



cTimelapse.cTrapSize.bb_width=cTrap.bb_width;
cTimelapse.cTrapSize.bb_height=cTrap.bb_height;

if nargin<4
    trapLocations=[];
end

image=cTimelapse.returnSingleTimepoint(timepoint);

if ~any(size(trapLocations))
    
    trapLocations=predictTrapLocations(image,cTrap);
    
end

[trapLocations trap_mask]=updateTrapLocations(image,cTrap,trapLocations);
cTimelapse.cTimepoint(timepoint).trapLocations=trapLocations;

for j=1:length(trapLocations)
    cTimelapse.cTimepoint(timepoint).trapInfo(j)=struct('segCenters',zeros(size(cTrap.trap1))>0,'cell',[],'cellsPresent',0,'cellLabel',[],'segmented',sparse(zeros(size(cTrap.trap1))>0),'trackLabel',sparse(zeros(size(cTrap.trap1))>0));
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.cellCenter=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.cellRadius=[];
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cell.segmented=sparse(zeros(size(cTrap.trap1))>0);
    cTimelapse.cTimepoint(timepoint).trapInfo(j).cellsPresent=0;
end
j=length(trapLocations);
if j<length(cTimelapse.cTimepoint(timepoint).trapInfo)
    cTimelapse.cTimepoint(timepoint).trapInfo(j+1:end)=[];
end



end

function [trapLocations trap_mask]=predictTrapLocations(image,cTrap)
timepoint_im=double(image);
timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
image_temp=padarray(timepoint_im,[cTrap.bb_height cTrap.bb_width],median(timepoint_im(:)));

cc=normxcorr2(cTrap.trap1,image_temp)+normxcorr2(cTrap.trap2,image_temp);

cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
cc_new=ones(size(cc,1),size(cc,2))*median(cc(:));
cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);

cc=cc_new;
cc=(imfilter(abs(cc),fspecial('disk',1)));
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);

cc=padarray(cc,[cTrap.bb_height,cTrap.bb_width]);
[max_im_cc, imax] = max(cc(:));
max_cc=max_im_cc;
trap_index=1;
trap_mask=false(size(cc,1),size(cc,2));

while max_cc> .75*max_im_cc
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    cc(ypeak-cTrap.bb_height*1:ypeak+cTrap.bb_height*1,xpeak-cTrap.bb_width*1:xpeak+cTrap.bb_width*1)=0;
    xcenter=xpeak-cTrap.bb_width;
    ycenter=ypeak-cTrap.bb_height;
    trapLocations(trap_index).xcenter=xcenter;
    trapLocations(trap_index).ycenter=ycenter;
    trap_mask(ypeak-cTrap.bb_height:ypeak+cTrap.bb_height,xpeak-cTrap.bb_width:xpeak+cTrap.bb_width)=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
    trap_index=trap_index+1;
    [max_cc, imax] = max(cc(:));   
end
trap_mask=trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
end




function [trapLocations trap_mask]=updateTrapLocations(image,cTrap,trapLocations)
timepoint_im=double(image);
timepoint_im=timepoint_im*cTrap.scaling/median(timepoint_im(:));
image_temp=padarray(timepoint_im,[cTrap.bb_height cTrap.bb_width],median(timepoint_im(:)));

cc=normxcorr2(cTrap.trap1,image_temp)+normxcorr2(cTrap.trap2,image_temp);
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);
cc_new=ones(size(cc,1),size(cc,2))*median(cc(:));
cc_new(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5)=cc(cTrap.bb_height*1.5:end-cTrap.bb_height*1.5,cTrap.bb_width*1.5:end-cTrap.bb_width*1.5);
cc=cc_new;
cc=(imfilter(abs(cc),fspecial('disk',1)));
cc=cc(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);

% cc=imfilter(cc,fspecial('log'));
% figure(101);imshow(cc,[]);colormap(jet);

cc=padarray(cc,[cTrap.bb_height,cTrap.bb_width]);
trap_mask=false(size(cc,1),size(cc,2));

for i=1:length(trapLocations)

    xcurrent=trapLocations(i).xcenter+cTrap.bb_width;
    ycurrent=trapLocations(i).ycenter+cTrap.bb_height;
    
    temp_im=cc(round(ycurrent-cTrap.bb_height/3:ycurrent+cTrap.bb_height/3),round(xcurrent-cTrap.bb_width/3:xcurrent+cTrap.bb_width/3));
    
    [maxval maxloc]=max(temp_im(:));
    [ypeak, xpeak] = ind2sub(size(temp_im),maxloc);
    
    xcenter=xcurrent+xpeak-cTrap.bb_width/3-1;
    ycenter=ycurrent+ypeak-cTrap.bb_height/3-1;

    trapLocations(i).xcenter=xcenter-cTrap.bb_width;
    trapLocations(i).ycenter=ycenter-cTrap.bb_height;
    trap_mask(round(ycenter-cTrap.bb_height:ycenter+cTrap.bb_height),round(xcenter-cTrap.bb_width:xcenter+cTrap.bb_width))=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
end
trap_mask=trap_mask(cTrap.bb_height+1:end-cTrap.bb_height,cTrap.bb_width+1:end-cTrap.bb_width);

end