function tl=scotConvert(ct, interval)
%scotConvert --- Creates a Scot timelapse from a cTimelapse object
%
% Synopsis:  tl = scotConvert(ct, interval)
%            tl = scotConvert(ct)
%
% Input:     ct = object of class cTimelapse
%            interval = double, time in minutes between timelapse frames
%
% Output:    tl = object of class Timelapse1

% Notes:	 This function creates a Scot timelapse object from a segmented
%            time lapse dataset created using the cTimelapse class for
%            machine-learning-based segentation.

if nargin~=2
    interval=5;%default interval between frames
end

if exist(ct.timelapseDir)==0
    ct.timelapseDir=uigetdir;
end

tl=Timelapse1(ct.timelapseDir, interval, ct.channelNames{1});

tl.TimePoints=length(ct.cTimepoint);

%Update the image file list.
%Entry for 'main' will already have been added by the constructor, based on
%the constructor input (ct.channelNames{1})
for n=1:length(ct.channelNames)
    if ~strcmp(ct.channelNames{n},tl.ImageFileList(1).identifier)
       tl.addImageFileList(ct.channelNames{n},tl.Moviedir,ct.channelNames{n},1)
    end    
end

%DELETE ANY CROPPED TIMEPOINTS


%Loop through the timepoints and cells, creating entries for Results and
%TrackingData

for t=1:tl.TimePoints
    numTraps=length(ct.cTimepoint(n).trapInfo);
    trackingnumber=0;  
    for tr=1:numTraps
        disp(['Timepoint:' num2str(t)])
        
        if ct.cTimepoint(t).trapInfo(tr).cellsPresent
            numCells=length(ct.cTimepoint(t).trapInfo(tr).cell); 
            %Are traps present?
            if ~isempty(ct.cTimepoint(t).trapLocations)
                %Location of trap - will be used for the region details
                x=ct.cTimepoint(t).trapLocations(tr).xcenter;
                y=ct.cTimepoint(t).trapLocations(tr).ycenter;
                leftx=max(1,x-ct.cTrapSize.bb_width);
                rightx=x+ct.cTrapSize.bb_width;
                topy=max(1,y-ct.cTrapSize.bb_height);
                bottomy=y+ct.cTrapSize.bb_height;
                                     
                leftx=round(leftx);
                rightx=round(rightx);
                topy=round(topy);
                bottomy=round(bottomy);
                for c=1:numCells
                    if ~isempty(ct.cTimepoint(t).trapInfo(tr).cell(c).cellCenter)

                        trackingnumber=trackingnumber+1;
                        image=full(ct.cTimepoint(t).trapInfo(tr).cell(c).segmented);
                        image=imfill(image,'Holes');
                        fullSize=false(tl.ImageSize(2), tl.ImageSize(1));


                        if y-ct.cTrapSize.bb_height<1%The trap image extends off the top of the image - need to correct that
                           height=round(bottomy);
                           topOfImage=size(image,1)-height;
                           image(1:topOfImage,:)=[];
                        end

                        if x-ct.cTrapSize.bb_width<1%The trap image extends off the left of the image - need to correct that
                           width=round(rightx);
                           leftOfImage=size(image,2)-width;
                           image(:,1:leftOfImage)=[];
                        end

                        try
                        fullSize(topy:bottomy,leftx:rightx)=image;
                        catch
                            disp('debug point');
                        end
                        fullSize=imrotate(fullSize,-(ct.image_rotation));
                        tl.Result(t).timepoints(trackingnumber).slices=sparse(fullSize);
                        tl.TrackingData(t).cells(trackingnumber).trackingnumber=trackingnumber;
                        tl.TrackingData(t).cells(trackingnumber).cellnumber=0;%Treat cells as not tracked
                        tl.TrackingData(t).cells(trackingnumber).methodobj=tl.RunMethod.ObjectNumber;
                        tl.TrackingData(t).cells(trackingnumber).levelobj=tl.ObjectNumber;

                        %Correct centroid coordinates to take rotation into
                        %account - first get the coordinates from ct
                        oldx=double(ct.cTimepoint(t).trapInfo(tr).cell(c).cellCenter(1)+leftx);
                        oldy=double(ct.cTimepoint(t).trapInfo(tr).cell(c).cellCenter(2)+topy);
                        oldtopy=topy;
                        oldleftx=leftx;
                        oldbottomy=bottomy;
                        oldrightx=rightx;
                        if ct.image_rotation==-95
                           newx=oldy;
                           newy=512-oldx;
                           newtopy=(512-oldleftx-2*ct.cTrapSize.bb_width);
                           newleftx=oldtopy;                       

                        else
                           newx=oldx;
                           newy=oldy;
                           newleftx=oldleftx;
                           newtopy=oldtopy;
                        end


                        tl.TrackingData(t).cells(trackingnumber).centroidx=newx;
                        tl.TrackingData(t).cells(trackingnumber).centroidy=newy;
                        tl.TrackingData(t).cells(trackingnumber).region=[newleftx newtopy min(2*ct.cTrapSize.bb_width, tl.ImageSize(1)) min(2*ct.cTrapSize.bb_height, tl.ImageSize(2))];
                        tl.TrackingData(t).cells(trackingnumber).segobject=tl.ObjectNumber;
                    end
                
                
                end
                
            
            
            else
                %There are no traps in this timelapse - region details need
                %to come from the segmented cell information
                
                for c=1:numCells
                    if ~isempty(ct.cTimepoint(t).trapInfo(tr).cell(c).cellCenter)

                        trackingnumber=trackingnumber+1;
                        image=full(ct.cTimepoint(t).trapInfo(tr).cell(c).segmented);
                        image=imfill(image,'Holes');
                        fullSize=false(tl.ImageSize(2), tl.ImageSize(1));
                        %Define location for the region surrounding the
                        %cell
                        %Centre of the region - defined by the cell centre
                        x=ct.cTimepoint(t).trapInfo.cell(c).cellCenter(1);
                        y=ct.cTimepoint(t).trapInfo.cell(c).cellCenter(2);
                        %Make a bounding box with sides equal to 2.5* the
                        %cell radius
                        height=ct.cTimepoint(t).trapInfo.cell(c).cellRadius*2.5;
                        width=ct.cTimepoint(t).trapInfo.cell(c).cellRadius*2.5;
                        
                        leftx=max(1,x-(width/2));
                        rightx=x+(width/2);
                        topy=max(1,y-(height/2));
                        bottomy=y+(height/2);
                        
                        
                        if y-height<1%The trap image extends off the top of the image - need to correct that
                           height=y-round(bottomy);
                           image(1,:)=true;
                           image=imfill(image,'holes');
                           image=imopen(image,strel('disk',2));
                        end

                        if x-width<1%The trap image extends off the left of the image - need to correct that
                           width=round(rightx);
                           image(:,1)=true;
                           image=imfill(image,'holes');
                           image=imopen(image,strel('disk',2));
                        end

                        try
                        fullSize=image;
                        catch
                            disp('debug point');
                        end
                        fullSize=imrotate(fullSize,-(ct.image_rotation));
                        tl.Result(t).timepoints(trackingnumber).slices=sparse(fullSize);
                        tl.TrackingData(t).cells(trackingnumber).trackingnumber=trackingnumber;
                        tl.TrackingData(t).cells(trackingnumber).cellnumber=0;%Treat cells as not tracked
                        tl.TrackingData(t).cells(trackingnumber).methodobj=tl.RunMethod.ObjectNumber;
                        tl.TrackingData(t).cells(trackingnumber).levelobj=tl.ObjectNumber;

                        %Correct centroid coordinates to take rotation into
                        %account - first get the coordinates from ct
                        if ct.trapsPresent
                            oldx=double(ct.cTimepoint(t).trapInfo(tr).cell(c).cellCenter(1)+leftx);
                            oldy=double(ct.cTimepoint(t).trapInfo(tr).cell(c).cellCenter(2)+topy);
                            oldtopy=topy;
                            oldleftx=leftx;
                            if ct.image_rotation==-90
                               newx=oldy;
                               newy=512-oldx;
                               newtopy=(512-oldleftx-2*ct.cTrapSize.bb_width);
                               newleftx=oldtopy;                       

                            else
                               newx=oldx;
                               newy=oldy;
                               newleftx=oldleftx;
                               newtopy=oldtopy;
                            end
                        else 
                            newx=x;
                            newy=y;
                            newleftx=leftx;
                            newtopy=topy;
                        end
                    
                    end

                        tl.TrackingData(t).cells(trackingnumber).centroidx=newx;
                        tl.TrackingData(t).cells(trackingnumber).centroidy=newy;
                        tl.TrackingData(t).cells(trackingnumber).region=[newleftx newtopy min(width, tl.ImageSize(1)) min(height, tl.ImageSize(2))];
                        tl.TrackingData(t).cells(trackingnumber).segobject=tl.ObjectNumber;
                    end
                
                
                end
            end
        end
        
   
    %Create an empty (preallocated) LevelObjects array
    numLevelObjects=tl.TimePoints * tl.RunMethod.numObjects;
    a=int16(0);
    a(1:numLevelObjects)=a;
    type='Preallocated';
    Type=cell(numLevelObjects,1);
    Type(:)={type};
    b=double([0 0 0 0]);
    b=repmat(b,[numLevelObjects 1]);
    c=int8(0);
    c(1:numLevelObjects)=c;
    tl.LevelObjects=[];
    tl.NumLevelObjects=0;
    tl.LevelObjects.ObjectNumber=a;
    tl.LevelObjects.Type=Type;
    tl.LevelObjects.RunMethod=a;
    tl.LevelObjects.SegMethod=a;
    tl.LevelObjects.Timelapse=a;
    tl.LevelObjects.Frame=a;
    tl.LevelObjects.Position=b;
    tl.LevelObjects.Timepoint=a;
    tl.LevelObjects.Region=a;
    tl.LevelObjects.TrackingNumber=c;
    tl.LevelObjects.CatchmentBasin=c;
    tl.LevelObjects.Centroid=b(:,1:2);

    
end
    %Track the timelapse
%     tl.RunTrackMethod.run(tl);


