function [imagestack_out] = returnSegmenationTrapsStack(cTimelapse,traps,timepoint,type)
%[imagestack_out] = returnSegmenationStackTimpoint(cTimelapse,traps,timepoint)
%returns a cell array of image stacks defined by the property channelsForSegment to be
%used in the cell identification, so that each element of the cell array is
%an image stack for the corresponding trap in the traps vector

if nargin<4
    type='trap';
end

for ci = 1:length(cTimelapse.channelsForSegment)  
    if strcmp(type,'trap')
        temp_im = cTimelapse.returnTrapsTimepoint(traps,timepoint,cTimelapse.channelsForSegment(ci));
        mval=mean(temp_im(:));
        if ci==1
            imagestack_out = cell(length(traps),1);
            [imagestack_out{:}] = deal(mval*ones(size(temp_im,1),size(temp_im,2),length(cTimelapse.channelsForSegment)));
        end
        for ti=1:length(traps)
            imagestack_out{ti}(:,:,ci) = temp_im(:,:,ti);
        end
    elseif strcmp(type,'whole')
        temp_im = cTimelapse.returnSingleTimepoint(timepoint,cTimelapse.channelsForSegment(ci));
        mval=mean(temp_im(:));
        if ci==1
            imagestack_out = cell(1,1);
            [imagestack_out{:}] = deal(mval*ones(size(temp_im,1),size(temp_im,2),length(cTimelapse.channelsForSegment)));
        end
        imagestack_out{1}(:,:,ci) = temp_im;
    elseif strcmp(type,'wholeTrap')
        temp_im = cTimelapse.returnTrapsTimepoint(traps,timepoint,cTimelapse.channelsForSegment(ci));
        mval=mean(temp_im(:));
        if ci==1
            imagestack_out = cell(1,1);
            colL=size(temp_im,2);rowL=size(temp_im,1);
            [imagestack_out{:}] = deal(mval*ones(size(temp_im,1),size(temp_im,2)*length(traps),length(cTimelapse.channelsForSegment)));
        end
        for ti=1:length(traps)
            imagestack_out{1}(:,1+(ti-1)*colL:ti*colL,ci) = temp_im(:,:,ti);
        end
    end 
end
end