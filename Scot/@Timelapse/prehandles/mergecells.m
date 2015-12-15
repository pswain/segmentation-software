function obj=mergecells(obj,cellnumber,mergewith)
% mergecells --- combines two cells (with different cell numbers) into a single record
%
% Synopsis:  obj=mergecells(obj,cellnumber,mergewith)
%
% Input:     obj = an object of a timelapse class
%            cellnumber = scalar, the number of one of the cells
%            mergewith = scalar, the cellnumber of the other cell
%
% Output:    obj = an object of a timelapse class

% Notes:    %For use when editing timelapse tracking data. When a cell has
%           %been assigned two different identities (cellnumbers) at
%           different timepoints this method allows them to be merged into
%           a single record.
thiscelldata=obj.Data(cellnumber,:);%Recorded data for thiscell
mergedcelldata=obj.Data(mergewith,:);%Recorded data for cell to merge with
tpswithdata=~(isnan(thiscelldata));%time points with data entries
mergedtpswithdata=~(isnan(mergedcelldata));%time points with data entries
tpswithoutdata=~(tpswithdata);
%Modify obj.Data:
%Replace time points in thiscelldata that have no data with data from the
%merged cell
thiscelldata(tpswithoutdata==1)=mergedcelldata(tpswithoutdata==1);
obj.Data(cellnumber,:)=thiscelldata;
obj.Data(mergewith,:)=nan(1,size(obj.Data,2));%deletes data from the merging cell
%Modify obj.Lengths
obj.Lengths(cellnumber)=sum(tpswithdata);%gives the number of timepoints with data
obj.Lengths(mergewith)=0;
%Modify obj.TrackingData structure and images (obj.Tracked and obj.Segmented)
%
%1. For timepoints at which the current cell was not segmented and the
%cell to merge with was, need to change the cell number for the entry
%for the cell to merge with (to that of the current cell)
%2. For any duplicate entries - need to delete the record for the cell
%to merge with
%
%find the timepoints at which the current cell was notsegmented AND the 
%merging cell is segmented
timepointstochange=find(tpswithoutdata+mergedtpswithdata==2);
%find the indices to the entries for the merging cell at those timepoints
%and set cell numbers to that of the saved cell.
if isempty(timepointstochange)~=1
    for t=1:size(timepointstochange,2)%loop through the time points you need to change
        tp=timepointstochange(t);%the timepoint to change
        cellnumbers=[obj.TrackingData(tp).cells(:).cellnumber];
        indextomergecell=cellnumbers==mergewith;
        %change the cell number of the merging cell to the new cell
        %number
        obj.TrackingData(tp).cells(indextomergecell).cellnumber=cellnumber;
        %Segmented and tracked images
        %Segmented - should be binary - no change here
        %Tracked - Need to set pixels belonging to the merging cell to
        %the value of the new cellnumber.
        mergingbin=obj.Tracked(:,:,tp)==mergewith;
        newtracked=obj.Tracked(:,:,tp);
        newtracked(mergingbin)=cellnumber;
        obj.Tracked(:,:,tp)=newtracked;                   

    end
end
%2. Check for any duplicates and delete the entries for the merging
%cell
duplicates=(tpswithdata+mergedtpswithdata)==2;
dupindices=find(duplicates);
if isempty(dupindices)~=1
    for n=1:size(dupindices,2)
        tp=dupindices(n);%the timepoint with duplicated cells
        cellnumbers=[handles.timelapse.TrackingData(tp).cells(:).cellnumber];
        indextomergecell=cellnumbers==mergewith;
        obj.TrackingData(tp).cells(indextomergecell)=[];
        %here need to delete the image also for the merging cell in the
        %segmented and tracked images
        mergingbin=obj.Tracked(:,:,tp)==mergewith;
        newtracked=obj.Tracked(:,:,tp);
        newsegmented=obj.Segmented(:,:,tp);
        newtracked(mergingbin)=0;
        newsegmented(mergingbin)=0;
        obj.Tracked(:,:,tp)=newtracked;
        obj.Segmented(:,:,tp)=newsegmented;
    end
end
end