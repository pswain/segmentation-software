function obj=datalength(obj)
% datalength --- Method to calculate the number of timepoints at which each cell is segmented
%
% Synopsis:  obj=datalength(obj)
%
% Input:     obj = an object of a timelapse class
% Output:    timelapse object

% Notes:    %gives the number of frames in which each cell is segmented in a measured
            %timelapse dataset. This information is used to exclude cells that are only
            %transiently detected, for example when plotting.

obj.Lengths=zeros(1,size(obj.Data,1));
c(:,:) =~isnan(obj.Data(:,1,:)); %cellnumber by time logical matrix of if the cell was successfully segmented.
                                 %Just take first channel, all other channels should be the same.
obj.Lengths = sum(c,2)';

end