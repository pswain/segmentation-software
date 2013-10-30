function handles=loadRawImages(handles, timelapseObj, identifier)
    % loadRawImages --- Loads raw images into the GUI for display
    %
    % Synopsis:  handles = loadRawImages (handles, timelapseObj,identifier)
    %                        
    % Input:     handles = structure, carrying GUI and timelapse information
    %            timelapseObj = object of a Timelapse class
    %            identifier = string present in one file per timepoint
    %
    % Output:    handles = structure, carrying GUI and timelapse information
    %            
    % Notes:     Loads images into the handles structure for GUI display.
    %            If identifier is 'main', loads the main timelapse
    %            segmentation target images. Otherwise loads the images
    %            with 'identifier' in their filename. Images are stored in
    %            the handles field handles.rawImages, which is a structure
    %            with the identifiers as field names.
    
    
showMessage(handles,'Preparing to load segmentation target images...');
if nargin<3
    identifier='main';
    if nargin==1
        timelapseObj=handles.timelapse;
    end
end
if strcmp(identifier,'main')
   identifier =  timelapseObj.ImageFileList(handles.timelapse.Main).identifier;
   label='main';
else
    label=identifier;
end

%add the selected channel to the image file list
[timelapseObj index]=timelapseObj.addImageFileList(label,timelapseObj.Moviedir,identifier,1);%This last input assumes there is only a single section per timepoint for this identifier
%Preallocate an array to take the images
handles.rawImages.(identifier)=[];



handles.rawImages.(identifier)(timelapseObj.ImageSize(2),timelapseObj.ImageSize(1),3,timelapseObj.TimePoints) = uint8(0);
handles.rawImages.(identifier)=uint8(handles.rawImages.(identifier));
%Define the image set to be displayed
handles.rawDisplay=identifier;
showMessage(handles,'Loading raw data...');
t=1;
for n=1:size(timelapseObj.ImageFileList(index).file_details,2)
   filename=[timelapseObj.ImageFileList(index).directory '/' timelapseObj.ImageFileList(index).file_details(n).timepoints.name];
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
        handles.rawImages.(identifier)(:,:,:,n)=image;% [y x rgb frame] 
    catch
        showMessage(handles,[filename ' may not be an image file'],'r');
    end
    MethodsSuperClass.showProgress(n/size(timelapseObj.ImageFileList(index).file_details,2)*100, 'Loading segmentation target images...');
end
MethodsSuperClass.showProgress(0, '');

