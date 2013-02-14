function timepoint=returnSingleTimepoint(cTimelapse,timepoint,channel)

if nargin<3
    channel=1;
end

timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{channel});

% if ~isempty(cTimelapse.magnification)
%     timepoint=imresize(timepoint,cTimelapse.magnification);
% end

if cTimelapse.image_rotation~=0
    timepoint=imrotate(timepoint,cTimelapse.image_rotation,'bilinear','loose');
end