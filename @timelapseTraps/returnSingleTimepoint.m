function timepoint=returnSingleTimepoint(cTimelapse,timepoint,channel)

if nargin<3
    channel=1;
end

try
    timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{channel});
catch
    timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{1});
    timepoint(:,:)=0;
    warning('There is no data in this channel at this timepoint');
end

% if ~isempty(cTimelapse.magnification)
%     timepoint=imresize(timepoint,cTimelapse.magnification);
% end

if cTimelapse.image_rotation~=0
    timepoint=imrotate(timepoint,cTimelapse.image_rotation,'bilinear','loose');
end