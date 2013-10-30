function [cellnumber varargout]=fillgap(obj, timepoint,centroid)
% fillgap --- Looks for segmented cells all at previous timepoints for tracking
%
% Synopsis:  [cellnumber report]=datalength(obj,timepoint,centroid)
%            [cellnumber report trackingnumber]=datalength(obj,timepoint,centroid)
%
% Input:     obj = an object of a timelapse class
%            timepoint = scalar, the current timepoint
%            centroid = 2 element vector, the coordinates ([x y]) of the
%                       centroid of the cell to be tracked
%
% Output:    cellnumber = scalar, the cellnumber of the found cell. Zero if
%                         no cell found
%            report = string, 'no cells found' if none found, 'none' if 
%                     there are no cells with the found cellnumber at the 
%                     current (input) timepoint, 'this' if there is an
%                     existing cell with the found cellnumber at the
%                     current timepoint but the cell to be tracked is
%                     closer to the found cell, or 'duplicate' if there is
%                     an existing cell at the current (input) timepoint
%                     that is closer to the found cell than is the cell to
%                     be tracked
%            trackingnumber = scalar, defined only in the case where
%                             report = 'this', the trackingnumber of the
%                             duplicate cell. This cell will need to have
%                             its cellnumber redefined

% Notes:    %For use during tracking - if a cell has no counterpart at the
            %previous timepoint - run this function to look at earlier
            %timepoints before creating a new cell. If a cell is found then
            %checks for any duplicates at the current cellnumber,
            %calculates if a duplicate is closer to the found cell than the
            %input cell to be tracked and reports.
tp=timepoint; 
cellnumber=0;
varargout={{''}};%Elco - this is a bit of a botch to make varargout work the way we thought it did

testimg=false(size(obj.Tracked,1));
trackno=obj.Segmented(round(centroid(2)),round(centroid(1)),timepoint);
testimg(obj.Segmented(:,:,timepoint)==trackno)=1;

while tp>1&&cellnumber==0
    tp=tp-1;
    thistracked=obj.Tracked(:,:,tp);
    cellnumbers=unique(thistracked(testimg));
    if size(cellnumbers,2)>1
        cellnumbers = cellnumber';
        %this really STUPID little if statement is because
        %unique returns a column vector for shape of matrix
        %except a row vector - in which case it returns a row
        %vector. To avoid confusion this if loop makes it a
        %column vector regardless.
    end
    cellnumbers(cellnumbers==0)=[];
    if size(cellnumbers,1)==1%assign cellnumber if the cell at this timepoint overlaps with only one cell at tp
        cellnumber=cellnumbers;
    end
    if size(cellnumbers,1)>1%the cell at this timepoint overlaps with >1 cell at tp
        %calculate which centroid is closest to the input
        %centroid
        centroids=zeros(size(cellnumbers,1),2);
        for n=1:size(cellnumbers,1)
           tracknum=find([obj.TrackingData(tp).cells.cellnumber]==cellnumbers(n));
           centroids(n,:)=[obj.TrackingData(tp).cells(tracknum).centroidx obj.TrackingData(tp).cells(tracknum).centroidy];                       
        end
        diffsqs=sum((centroids-ones(size(centroids,1),1)*centroid).^2,2);
        [value ind]=min(diffsqs);
        cellnumber=cellnumbers(ind);                   
    end
    if isempty(cellnumber)
        cellnumber=0;
    end

end

if cellnumber>0
%are there any duplicates?
   if any([obj.TrackingData(timepoint).cells.cellnumber]==cellnumber);
       %two cells at the current timepoint are tracked to
       %cellnumber

       %One will have to be defined as a new cell. Calculate which
       %is closest to the previous centroid and return that information

       %First find the centroid of the cell at tp with the
       %cellnumber:
       cellnos=[obj.TrackingData(tp).cells.cellnumber];%the cell numbers at tp
       tracknos=[obj.TrackingData(tp).cells.trackingnumber];%the tracking numbers at tp
       match=cellnos==cellnumber;
       trackingnumber=find(match);           
       cellnumbercentroid=[obj.TrackingData(tp).cells(trackingnumber).centroidx obj.TrackingData(tp).cells(trackingnumber).centroidy];
       %Then find the centroid of the duplicate cell at the current timepoint:
       cellnos=[obj.TrackingData(timepoint).cells.cellnumber];
       tracknos=[obj.TrackingData(timepoint).cells.trackingnumber];
       match=cellnos==cellnumber;
       trackingnumber=find(match);
       duplicatecentroid=[obj.TrackingData(timepoint).cells(trackingnumber).centroidx + obj.TrackingData(timepoint).cells(trackingnumber).region(1) ...
                            obj.TrackingData(timepoint).cells(trackingnumber).centroidy + obj.TrackingData(timepoint).cells(trackingnumber).region(2)];
%Calculate square distances
       thiscelldistance=sum((centroid-cellnumbercentroid).^2);
       dupcelldistance=sum((duplicatecentroid-cellnumbercentroid).^2);
       if thiscelldistance>dupcelldistance
           varargout{1}{1}='duplicate';%the duplicate cell is closer - need to initiate a new cell number for the input cell
       else
           varargout{1}{1}='this';%the input cell is closer - need to initiate a new cell number for the duplicate cell
           varargout{1}{2}=trackingnumber;%the tracking number of the duplicate cell
       end
   else%there are no duplicates
       varargout{1}{1}='none';
   end
else%cellnumer is 0 - no previous cells were found
    varargout{1}{1}='no cells found';
end
end