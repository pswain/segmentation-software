function trapsTimepoint=returnTrapsFromImage(cTimelapse,image,timepoint,traps)
%trapsTimepoint=returnTrapsTimepoint(cTimelapse,traps,timepoint,channel,type)
%If there are traps in the timelapse, this returns a 3D image containg the set of 
% traps indicated at the timepoint indicated. If there are no traps in the
% timelapse however, it return the entire frame in a single 2D image.

if nargin<4
    traps=1:length(cTimelapse.cTimepoint(timepoint).trapInfo);
end


cTrap=cTimelapse.cTrapSize;
bb=max([cTrap.bb_width cTrap.bb_height])+100;

if islogical(image)
    pdval=0;
else
%     pdval=median(image(:));
    pdval=mean(image(:));
end

bb_image=padarray(image,[bb bb],pdval);
%if the traps have been converted to be flat in a single image
if size(image,1)==(cTrap.bb_height*2+1)
    trapsTimepoint=zeros(2*cTrap.bb_height+1,2*cTrap.bb_width+1,length(traps),'double');
    for j=1:length(traps)
        x=(j-1)*(cTrap.bb_width*2+1)+bb;
        temp_im=bb_image(1+bb:bb+2*cTrap.bb_height+1,x+1:x+2*cTrap.bb_width+1);
        if pdval
            temp_im(temp_im==0)=pdval;%mean(temp_im(:));
        end
        trapsTimepoint(:,:,j)=temp_im;
    end
%else, if the image is the size of the image acquired by the camera
else
    trapsTimepoint=zeros(2*cTrap.bb_height+1,2*cTrap.bb_width+1,length(traps),'double');
    for j=1:length(traps)
        y=round(cTimelapse.cTimepoint(timepoint).trapLocations(traps(j)).ycenter + bb);
        x=round(cTimelapse.cTimepoint(timepoint).trapLocations(traps(j)).xcenter + bb);
        temp_im=bb_image(y-cTrap.bb_height:y+cTrap.bb_height,x-cTrap.bb_width:x+cTrap.bb_width);
        if pdval
            temp_im(temp_im==0)=pdval;%mean(temp_im(:));
        end
        trapsTimepoint(:,:,j)=temp_im;
    end
end
