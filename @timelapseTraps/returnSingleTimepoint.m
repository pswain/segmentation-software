function timepoint=returnSingleTimepoint(cTimelapse,timepoint,channel)

if nargin<3
    channel=1;
end
tp=timepoint;
if channel<=length(cTimelapse.cTimepoint(timepoint).filename)
        timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{channel});
else
        timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{1});
    timepoint(:,:)=0;
    warning('There is no data in this channel at this timepoint');
end
% try
%     timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{channel});
% catch
%     timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{1});
%     timepoint(:,:)=0;
%     warning('There is no data in this channel at this timepoint');
% end
% 
% if ~isempty(cTimelapse.magnification)
%     timepoint=imresize(timepoint,cTimelapse.magnification);
% end

if isfield(cTimelapse.cTimepoint(tp),'image_rotation') & ~isempty(cTimelapse.cTimepoint(tp).image_rotation)
    image_rotation=cTimelapse.cTimepoint(tp).image_rotation;
else
    image_rotation=cTimelapse.image_rotation;
end
    
if image_rotation~=0
    timepoint=imrotate(timepoint,image_rotation,'bilinear','loose');
end