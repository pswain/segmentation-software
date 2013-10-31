function [image1 image2]=colourCells(obj,timepoint)

%Make colour map
cc=lines(length(obj.Result(timepoint).timepoints));
%load target image
filename=[obj.ImageFileList(1).directory filesep obj.ImageFileList(1).file_details(1).timepoints.name];
target=imread(filename);


image1=zeros(obj.ImageSize(2),obj.ImageSize(1),3);
image2=target;


for n=1:length(obj.Result(timepoint).timepoints)
    if~isempty(obj.Result(timepoint).timepoints(n).slices)
    image1(:,:,1)=image1(:,:,1)+obj.Result(timepoint).timepoints(n).slices.*cc(n,1);
    image1(:,:,2)=image1(:,:,2)+obj.Result(timepoint).timepoints(n).slices.*cc(n,2);
    image2(:,:,3)=image1(:,:,3)+obj.Result(timepoint).timepoints(n).slices.*cc(n,3);
    
    faded=cc(n,:)*.5;
    result=full(obj.Result(timepoint).timepoints(n).slices);
    image2(:,:,1)=image2(:,:,1)+im2uint8(result.*faded(1));
    image2(:,:,2)=image2(:,:,2)+im2uint8(result.*faded(2));
    image2(:,:,3)=image2(:,:,3)+im2uint8(result.*faded(3));
    end
end