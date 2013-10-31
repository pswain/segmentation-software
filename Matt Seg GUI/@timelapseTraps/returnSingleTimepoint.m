function timepoint=returnSingleTimepoint(cTimelapse,timepoint,channel)

if nargin<3
    channel=1;
end
tp=timepoint;
if channel<=length(cTimelapse.cTimepoint(timepoint).filename)
    file=cTimelapse.cTimepoint(timepoint).filename{channel};
    loc=strfind(file,'/');
    if loc
        file=file(loc(end)+1:end);
        cTimelapse.cTimepoint(timepoint).filename{channel}=file;
    end
    ffile=fullfile(cTimelapse.timelapseDir,file);
    try
        timepoint=imread(ffile);
    catch
        folder =0;
        h=errordlg('Directory seems to have changed');
        uiwait(h);
        while folder==0
            fprintf(['Select the correct folder for: ',cTimelapse.timelapseDir]);
            folder=uigetdir(pwd,['Select the correct folder for: ',cTimelapse.timelapseDir]);
            cTimelapse.timelapseDir=folder;
        end
        ffile=fullfile(cTimelapse.timelapseDir,file);
        timepoint=imread(ffile);
    end
else
    if cTimelapse.imSize
        timepoint=zeros(cTimelapse.imSize)
    else
        timepoint=imread(cTimelapse.cTimepoint(timepoint).filename{1});
        timepoint(:,:)=0;
        cTimelapse.imSize=size(timepoint);
    end
    disp('There is no data in this channel at this timepoint');
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