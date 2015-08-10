function [obj newhighest]=trackTimepoint(obj,timepoint)
% trackTimepoint --- %tracking function for individual timepoints
%
% Synopsis:  [obj newhighest] = trackTimepoint(obj,timepoint)
%
% Input:     obj = an object of a timelapse class
%            timepoint = scalar, timepoint to be tracked
%            
%            
% Output:    obj == an object of a timelapse class
%            newhighest == scalar, the highest cellnumber in the timelapse

% Notes:     ADD ANOTHER CALL TO FILLGAP - IN CASE NO CELL IS FOUND IN THE
% REF TIMEPOINT WITHIN THE MAXDRIFT RANGE
highest=obj.gethighest;%the largest cellnumber in the dataset
if timepoint==1
   reftimepoint=2;
else
   reftimepoint=timepoint-1;
end
%only attempt tracking if there are segmented cells in both this and the reference timepoint
if sum(isfinite([obj.TrackingData(timepoint).cells.cellnumber]))>0 && sum(isfinite([obj.TrackingData(reftimepoint).cells.cellnumber]))>0
   thiscentroidx=[obj.TrackingData(timepoint).cells.centroidx];%coordinates of centroids of all cells in the current timepoint
   thiscentroidy=[obj.TrackingData(timepoint).cells.centroidy];
   thisregion=reshape([obj.TrackingData(timepoint).cells.region],5,size(thiscentroidx,2));
   thiscentroid(:,1)=thiscentroidx(:)+thisregion(1,:)';
   thiscentroid(:,2)=thiscentroidy(:)+thisregion(2,:)';
   refcentroidx=[obj.TrackingData(reftimepoint).cells.centroidx];%coordinates of centroids of all cells in the reference timepoint
   refcentroidy=[obj.TrackingData(reftimepoint).cells.centroidy];
   refregion=reshape([obj.TrackingData(reftimepoint).cells.region],5,size(refcentroidx,2));
   refcentroid(:,1)=refcentroidx(:)+refregion(1,:)';
   refcentroid(:,2)=refcentroidy(:)+refregion(2,:)';
   %preassign an array to record the distances between objects in this
   %time point and the nearest objects in the reference time point.
   assigneddists=zeros(size(thiscentroidx));
   assignedcellnos=zeros(size(thiscentroidx));
       for i=1:size(thiscentroidx,2);%loop through objects in this image
            disp(strcat('tracking cell with trackingnumber:',num2str(i)));%COMMENT THIS FOR SPEED
            diffs=[refcentroid(:,1)-thiscentroid(i,1) refcentroid(:,2)-thiscentroid(i,2)];%differences
            diffsqd=diffs.^2;
            centdistsqd=sum(diffsqd,2);
            [c k]=min(centdistsqd);%k is the index (in the reference timepoint arrays refcentroidx and y) of the nearest centroid to i
            if c<=obj.Defaults.maxdrift^2%only assign the number of the nearest object from the previous image if it's near enough.
                assigneddists(i)=c;%the square of the distance of the object i to the nearest object in the previous image
                %Now the cell number for this object (i) should be: obj.TrackingData(reftimepoint).cells(k).cellnumber;
                %But before accepting this - need to check if this cellnumber has already been used at this timepoint.
                if any(assignedcellnos==obj.TrackingData(reftimepoint).cells(k).cellnumber);%this cell number has already been assigned - need to work out which is closer
                    duplicate=assignedcellnos==obj.TrackingData(reftimepoint).cells(k).cellnumber;
                    %duplicate should now be a logical index to the cell that has already been assinged this cell number.
                    %which is closest, i or duplicate?
                    if assigneddists(i)<=assigneddists(duplicate)%The previously-assigned object (duplicate) is further away.
                    %We conclude that the previous object  was not segmented in
                    %the reference image - could be a new cell or there might
                    %have been a segmentation failure in the reference image.
                    %Use the fillgap function to address
                    %this 2nd possibility:
                    duptrackingnumber=find(duplicate);
                    [dupcellnumber varargout]=obj.fillgap(timepoint,thiscentroid(duptrackingnumber,:));
                    if dupcellnumber>0%a cell was found at a previous timepoint at the position of thiscentroid(duptrackingnumber,:)
                        switch varargout{1}                                        
                            case 'none'%no duplicates were found in the fillgap method
                                obj.TrackingData(timepoint).cells(duptrackingnumber).cellnumber=dupcellnumber;
                                assignedcellnos(duptrackingnumber)=dupcellnumber;
                            case 'this'%a duplicate was found but this cell is closer
                                %deal with this cell first - as above
                                obj.TrackingData(timepoint).cells(duptrackingnumber).cellnumber=dupcellnumber;
                                assignedcellnos(duptrackingnumber)=dupcellnumber;
                                %need to sort out the other cell
                                trackingnumber=varargout{2};
                                highest=highest+1;
                                obj.TrackingData(timepoint).cells(trackingnumber).cellnumber=highest;
                                ind = find(obj.Segmented(:,:,timepoint)==trackingnumber);
                                assignedcellnos(trackingnumber)=highest;
                            case 'duplicate'%the duplicate was closer - need a new cell number for this cell
                                highest=highest+1;
                                obj.TrackingData(timepoint).cells(duptrackingnumber).cellnumber=highest;
                                assignedcellnos(duptrackingnumber)=highest;
                        end
                    else%Cellnumber is zero - no cell was found at previous timepoints in the centroid position of the duplicate cell - must be a new one.
                            highest=highest+1;
                            obj.TrackingData(timepoint).cells(duptrackingnumber).cellnumber=highest;
                            assignedcellnos(duptrackingnumber)=highest;                                        
                    end
                       %The duplicate cell is dealt with. Now assign the correct cell number to i.
                       obj.TrackingData(timepoint).cells(i).cellnumber=obj.TrackingData(reftimepoint).cells(k).cellnumber;
                       assignedcellnos(i)=obj.TrackingData(timepoint).cells(i).cellnumber;
                    else%the previously tracked cell (duplicate) is closer.
                        %In this case check for gaps - look for cells at the centroid position of this cell at previous timepoints
                        [cellnumber varargout]=obj.fillgap(timepoint,thiscentroid(i,:));
                        if cellnumber>0%a cell was found at a previous timepoint at the position of thiscentroid(i,:)
                            switch varargout{1}                                        
                                case 'none'%no duplicates were found in the fillgap method
                                    obj.TrackingData(timepoint).cells(i).cellnumber=cellnumber;
                                    assignedcellnos(i)=cellnumber;
                                case 'this'%a duplicate was found but this cell is closer
                                    %deal with this cell first - as above
                                    obj.TrackingData(timepoint).cells(i).cellnumber=cellnumber;
                                    assignedcellnos(i)=cellnumber;
                                    %need to sort out the other cell
                                    trackingnumber=varargout{2};
                                    highest=highest+1;
                                    obj.TrackingData(timepoint).cells(trackingnumber).cellnumber=highest; 
                                    assignedcellnos(trackingnumber)=highest;
                                case 'duplicate'%the duplicate was closer - need a new cell number for this cell
                                    highest=highest+1;
                                    obj.TrackingData(timepoint).cells(i).cellnumber=highest;
                                    assignedcellnos(i)=highest;
                            end
                        else%Cellnumber is zero - no cell was found at previous timepoints in the centroid position of this cell - this must be a new one.
                                highest=highest+1;
                                obj.TrackingData(timepoint).cells(i).cellnumber=highest;
                                assignedcellnos(i)=highest;                                        
                        end
                    end
                else%the found nearest cell number has yet not been assigned - can assign it to this cell
                    obj.TrackingData(timepoint).cells(i).cellnumber=obj.TrackingData(reftimepoint).cells(k).cellnumber;
                    %write correct grey level (the cell number) to the
                    %object i in the tracked image at the current
                    %timepoint.
                    assignedcellnos(i)=obj.TrackingData(timepoint).cells(i).cellnumber;
                end
            else%the found nearest object is further away from the object at this timepoint than the maximum - may be a new cell
                %RUN FILLGAP HERE IN CASE OF SEGMENTATIION
                %FAILURE AT THE PREVIOUS TIMEPOINT
                highest=highest+1;
                obj.TrackingData(timepoint).cells(i).cellnumber=highest;
                assignedcellnos(i)=highest;
            end
       end% of i loop through objects in this image
     newhighest=highest;
else%there are no cells in this timepoint
   newhighest=highest;                   
end
end

