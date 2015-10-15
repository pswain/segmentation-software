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
b=isnan(obj.Data);
c=1-b;
for n=1:size(obj.Data,1)
   obj.Lengths(n)=sum(c(n,:));
end
end