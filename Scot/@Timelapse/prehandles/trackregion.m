function [timepoint region cell]=trackregion(obj,region,timepoint,cellnumber)
% trackregion --- retracks a single region within the context of a timelapse
%
% Synopsis:  [timepoint region cell]=trackregion(obj,region, timepoint, cellnumber)
%
% Input:     obj = an object of a timelapse class
%            region = an object of a region class
%            timepoint = an object of a timepoint class
%            cellnumber = scalar, the number of the currently selected cell
%
% Output:    timepoint = an object class timepoint3
%            region = an object class region3
%            cell = an object class onecell3

% Notes:     Tracking function - to be used when a single region at one
%            timepoint has been modified. Returns a modified region (with
%            cell numbers defined), and timepoint and onecell objects that
%            can be accepted or rejected. Does not modify the timelapse
%            object - only returns modified region, timepoint and onecell
%            objects - so that a saved version of the timelapse object is
%            retained for the user to choose to keep or discard.

%Is this the first timepoint? If so, use the data from timepoint 2 to track
%Otherwise use the previous timepoint.
if region.Timepoint==1
   trackfrom=2;
else
   trackfrom=region.Timepoint-1;
end
numcells=size(region.TrackingData.cells,2);%number of cells in the newly-modified region
%Get the cell numbers that are already assigned in the
%current timepoint - excluding those with centroids in this region -
%this is for later duplicate-checking. Cells with centroids in the region
%are removed because they will have been recalculated and will be
%represented in the modified region
existingcellnos=[timepoint.TrackingData.cells(:).cellnumber];
existingcentroids(:,1)=[timepoint.TrackingData.cells(:).centroidx];
existingcentroids(:,2)=[timepoint.TrackingData.cells(:).centroidy];
%use region information to locate these local centroid positions in the
%complete image
existingregions=[timepoint.TrackingData.cells(:).region];
existingregions=reshape(existingregions,5,[])';
existingcentroids=existingcentroids+existingregions(:,1:2);
%Remove cells with centroids in the modified region
toremove=existingcentroids(:,1)>=region.TopLeftx & existingcentroids(:,1)<region.TopLeftx + region.xLength...
   &existingcentroids(:,2)>=region.TopLefty & existingcentroids(:,2)<=region.TopLefty + region.yLength;
existingcellnos(toremove)=nan;
trackingnos=find(toremove);
for n=1:size(trackingnos,1)
   timepoint.Tracked(timepoint.Tracked==timepoint.TrackingData.cells(trackingnos(n)).cellnumber)=0;%delete this cellnumber from the tracked image
   timepoint.TrackingData.cells(trackingnos(n)).cellnumber=nan;
end
%There may also be parts of cells from other regions in this region.
%Will need a record of these to check if any of the new cells
%overlap with them, in which case the old cells need to be removed
%record the original result - will be needed to check if any
%original cells (with different cell numbers from newly-tracked cells)
%overlap with the new cells    
oldresult=timepoint.Tracked(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1);
%Also need to know the highest assigned cell number in the data set
%- in case we get any new cells - these will be assigned new cell
%numbers
cellinfo=[obj.TrackingData.cells];
allcellnums=[cellinfo.cellnumber];
highest=max(allcellnums);
%start loop through the cells in the modified region - assigning cell numbers
for i=1:numcells
       %get the centroid position (in the whole image - not just the region) of the newly-segmented cell to be considered (i)
       localnewregioncentroid=[region.TrackingData.cells(i).centroidx region.TrackingData.cells(i).centroidy];
       newregioncentroid=localnewregioncentroid+region.TrackingData.cells(i).region(1:2);
       numtrackfromcells=size(obj.TrackingData(trackfrom).cells,2);%number of cells in the reference timepoint
       distsqd=nan(numtrackfromcells,1); %initialise array to take distance data
       %loop through the cells in the previous timepoint - calculate the square distances of each cell to the cell being considered (i).
   for j=1:numtrackfromcells
       if isfinite (obj.TrackingData(trackfrom).cells(j).cellnumber)%avoids deleted cells - cellnumber=nan
           localcentroid=[obj.TrackingData(trackfrom).cells(j).centroidx obj.TrackingData(trackfrom).cells(j).centroidy];
           trackfromcentroid=localcentroid+obj.TrackingData(trackfrom).cells(j).region(1:2);
           distsqd(j)=sum((trackfromcentroid-newregioncentroid).^2);
       end
   end
   [c k]=min(distsqd);%k is the index (trackingnumber) of the cell nearest to i in the trackfrom timepoint
   distance=sqrt(c);
   if distance<=obj.Defaults.maxdrift%is the found cell near enough?
        %now need to check for and resolve any duplicates
        foundcellnumber=obj.TrackingData(trackfrom).cells(k).cellnumber;
        ncells=size(timepoint.TrackingData.cells,2);%ncells=the number of cells at the current timepoint - needed to define new tracking numbers (numcells=number of cells in the modified region)
        if any(existingcellnos==foundcellnumber)%there is a duplication - this cell number already exists at the current timepoint
            %which is closest?
            duplicate=existingcellnos==foundcellnumber;%index to duplicated cell
            %centroid position of the cell with this cellnumber at the reference timepoint
            localcentroid=[obj.TrackingData(trackfrom).cells(k).centroidx obj.TrackingData(trackfrom).cells(k).centroidy];
            trackfromcentroid=localcentroid+obj.TrackingData(trackfrom).cells(k).region(1:2);
            %calculate the distance from the duplicate cell to the centroid of the cell at the reference timepoint
            trackfromcentroid=repmat(trackfromcentroid,size(existingcentroids(duplicate),2),1);
            duplicatedifferences=(existingcentroids(duplicate,:)-trackfromcentroid);
            duplicatedistance=sqrt(sum(duplicatedifferences.^2));
            if duplicatedistance>distance%the newly found cell is closest - need to assign a new cell number to the existing cell and add the new cell's details to timepoint.TrackingData
                %first deal with the existing cell
                %(It is probably not sensible to try to track this
                %cell - ie find the nearest cell in the reference
                %time point - because tracking will have been
                %attempted after the intitial segmentation and if
                %there was a better cell than the one that was
                %assigned then it would have been assigned instead.
                %So find out what the highest existing cell number
                %in the dataset it and assign this number +1)
                timepoint.TrackingData.cells(duplicate).cellnumber=highest+1;
                regcellnos=[region.TrackingData.cells.cellnumber];
                dupcellindex=find(regcellnos==foundcellnumber);
                region.TrackingData.cells(dupcellindex).cellnumber=highest+1;
                %update timepoint.Tracked
                timepoint.Tracked(timepoint.Tracked==foundcellnumber)=highest+1;
                highest=highest+1;
                %Now deal with the cell from the newly-modified region (i)
                region.TrackingData.cells(i).cellnumber=foundcellnumber;
                region.TrackingData.cells(i).trackingnumber=ncells+1;
                timepoint.TrackingData.cells(ncells+1)=region.TrackingData.cells(i);
                %update timepoint.Tracked
                thiswsh=region.Watershed==region.TrackingData.cells(i).catchmentbasin;
                binary=region.Result>0;
                pixels=(thiswsh+binary)>1;
                regionimage=timepoint.Tracked(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1);                    
                regionimage(pixels)=foundcellnumber;%write the new cell number to these pixels
                timepoint.Tracked(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1)=regionimage;
            else%the existing cell is closer than i - need to assign a new cell number to the new cell - leave the existing cell as it is.
                ncells=size(timepoint.TrackingData.cells,2);
                region.TrackingData.cells(i).cellnumber=highest+1;
                %update timepoint.Tracked image
                thiswsh=region.Watershed==region.TrackingData.cells(i).catchmentbasin;
                binary=region.Result>0;
                pixels=(thiswsh+binary)>1;
                regionimage=timepoint.Tracked(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1);                    
                regionimage(pixels)=highest+1;%write the new cell number to these pixels
                timepoint.Tracked(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1)=regionimage;
                highest=highest+1;
                region.TrackingData.cells(i).trackingnumber=ncells+1;
                timepoint.TrackingData.cells(ncells+1)=region.TrackingData.cells(i);
            end
        else%the cell number is not found in the existing data at this time point - no duplication
            region.TrackingData.cells(i).cellnumber=foundcellnumber;
            region.TrackingData.cells(i).trackingnumber=ncells+1;
            timepoint.TrackingData.cells(ncells+1)=region.TrackingData.cells(i);
            %update the timepoint.Tracked image                  
            regionimage=timepoint.Tracked(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1);
            if isempty (region.TrackingData.cells(i).catchmentbasin)
                thiswsh=region.Watershed;
            else
            thiswsh=region.Watershed==region.TrackingData.cells(i).catchmentbasin;
            end
            binary=region.Result>0;
            pixels=(thiswsh+binary)>1;
            regionimage(pixels)=foundcellnumber;%write the new cell number to these pixels
            timepoint.Tracked(region.TopLefty:region.TopLefty+region.yLength-1,region.TopLeftx:region.TopLeftx+region.xLength-1)=regionimage;
        end
   else%the distance from cell i to the nearest cell in the reference time point is too far - outside the maximum drift allowed
       %Define a new cell number and tracking number
       region.TrackingData.cells(i).cellnumber=highest+1;
       highest=highest+1;
       ncells=size(obj.TrackingData(region.Timepoint).cells,2);%the number of cells at the current timepoint - needed to define new tracking numbers
       region.TrackingData.cells(i).trackingnumber=ncells+1;              
       timepoint.TrackingData.cells(ncells+1)=region.TrackingData.cells(i);
   end
   %Update the existingcellnos and existingcentroids arrays - so that newly-assigned
   %cellnumbers are also checked for duplicates
   existingcellnos=[timepoint.TrackingData.cells(:).cellnumber];
   existingcentroids=[];
   existingcentroids(:,1)=[timepoint.TrackingData.cells(:).centroidx];
   existingcentroids(:,2)=[timepoint.TrackingData.cells(:).centroidy];
   existingregions=[timepoint.TrackingData.cells(:).region];
   existingregions=reshape(existingregions,5,[])';
   existingcentroids=existingcentroids+existingregions(:,1:2);
end%end of i loop - through the cells in the modified region
%
%Before exiting the method - need to update the data in the
%timepoint object and also create a onecell object to be returned.
%
%First check if the original had any cells that overlap with cells
%that have been detected in the new region. Those need to be deleted.
overlapping=oldresult((region.Result~=0));
overlapcellnos=unique(overlapping);
%Delete the overlapping cells
if any(overlapping)
   for n=1:size(overlapcellnos(1))%There may be a faster way to do this - avoiding the loop
        oldresult(oldresult==overlapcellnos(n))=0;
        %Find tracking number and delete from TrackingData
        %structure
        trackno=timepoint.findtrackingnumber(overlapcellnos(n));
        timepoint.TrackingData.(trackno).cells.cellnumber=nan;
        %delete from timepoint.Tracked image
        timepoint.Tracked(timepoint.Tracked==overlapcellnos(n))=0;
   end
end
%Create onecell object to return
%For that you need to know the correct cellnumber to use. The number
%of the input cell (starting cell) is cellnumber. If this is present
%after retracking then the segmentation/retracking has been
%successful and you're fine.
if (any([region.TrackingData.cells.cellnumber]==cellnumber))
    cell=onecell3(region,timepoint,cellnumber);
else%the original cell number is not present in the retracked data 
    trackfromcellnos=[obj.TrackingData(trackfrom).cells.cellnumber];
    [nearesttimepoint,x,y,trackingnumber]=obj.findnearest(cellnumber,timepoint.Timepoint);
    %The original cell number may be absent because it was not segmented
    %at the reference timepoint. Altenatively it may not have been
    %segmented in the modified region at this timepoint
    if any (trackfromcellnos==cellnumber)%cell was segmented at the reference timepoint
       %segmentation has failed for this cell at the current timepoint
       %Make a onecell2 object - construtor assumes segmentation has failed
       nearesttimepointobj=timepoint3(timepoint.Timepoint,obj);
       cell=onecell2(region,timepoint,nearesttimepointobj,trackingnumber);           
    else%cell was not segmented at the reference timepoint
        %Find the nearest timepoint at which it was segmented, check which 
        %catchment basin its centroid is in in the newly-segmented region. 
        %Create a cell using that catchment basin (may or may not have been
        %segmented)
        %
        %(This sort of code could be used in the i loop above - before assigning cell
        %numbers - look to find the nearest timepoint at which a cell in the
        %appropriate catchment basin was segmented then assign that cell
        %number to the cell - this would avoid gaps in tracks that then have
        %to be merged - but would slow the execution down and also you would
        %need extra duplication checks making things very complicated. Here
        %it is only done after the if/else statement above so we know there
        %can be no duplication).
        centroidinregion=round([x-region.TopLeftx y-region.TopLefty]);
        catchmentbasin=region.Watershed(centroidinregion(2),centroidinregion(1));
        if catchmentbasin==0%just in case it's on a watershed line - assign a nearby catchment basin
            catchmentbasin=region.Watershed(centroidinregion(2)+1,centroidinregion(1));
            if catchmentbasin==0%give up and assign any old catchment basin
                catchmentbasin=1;
            end
        end
        %Is there a cell in this catchment basin in the newly-segmented region?
        if any ([region.TrackingData.cells.catchmentbasin]==catchmentbasin)%cell is segmented - should be re-assigned the original cell number
            origcellindex=[region.TrackingData.cells.catchmentbasin]==catchmentbasin;%Find an index to the entry for this cell in region.TrackingData
            origcellindex=find(origcellindex);
            wrongcellnumber=region.TrackingData.cells(origcellindex).cellnumber;%record the old cell number - needed to find it in the timepoint object
            region.TrackingData.cells(origcellindex).cellnumber=cellnumber;
            %same for the timepoint object
            origcellindex=[timepoint.TrackingData.cells.cellnumber]==wrongcellnumber;
            origcellindex=find(origcellindex);
            timepoint.TrackingData.cells(origcellindex).cellnumber=cellnumber;
            timepoint.Tracked(timepoint.Tracked==wrongcellnumber)=cellnumber;
            cell=onecell1(region,timepoint,cellnumber);
        else%cell is not segmented in the retracked region (or in the reference timepoint) 
            %So - create a failed segmentation onecell object
            nearesttimepointobj=timepoint3(timepoint.Timepoint,obj);
            cell=onecell2(region,timepoint,nearesttimepointobj,trackingnumber);
        end
    end
end
%Write the data to timepoint object
timepoint=timepoint.measurefluorescence(highest);%highest is the number of cells in the data set.
end