function handles=loadMainImages(handles, timelapseObj)

showMessage(handles,'Preparing to load segmentation target images...');
if nargin==1
    timelapseObj=handles.timelapse;
end

handles.mainImages(timelapseObj.ImageSize(2),timelapseObj.ImageSize(1),3,timelapseObj.TimePoints) = uint8(0);
showMessage(handles,'Loading segmentation target images...');
t=1;
for n=1:timelapseObj.TimePoints
   filename=[timelapseObj.ImageFileList(end).directory '/' timelapseObj.ImageFileList(timelapseObj.Main).file_details(n).timepoints.name];
    try
        showMessage(handles,['Loading segmentation target image ' num2str(n) ' out of ' num2str(timelapseObj.TimePoints)]);
        image=imread(filename);
        image=double(image);
        image_min=min(image(:));
        image_max=max(image(:)-image_min);
        image=image-image_min;
        image=image*1/image_max;
        image=im2uint8(image);
        image=repmat(image,[1 1 3]);
        handles.mainImages(:,:,:,n)=image;% [y x rgb frame] 
    catch
        showMessage(handles,[filename ' may not be an image file'],'r');
    end
    MethodsSuperClass.showProgress(n/timelapseObj.TimePoints*100, 'Loading segmentation target images...');
end
MethodsSuperClass.showProgress(0, '');

